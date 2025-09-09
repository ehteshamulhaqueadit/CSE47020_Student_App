import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:cse47020_student_app/tools/prints.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';

class BracuAuthManager {
  static final BracuAuthManager _instance = BracuAuthManager._internal();
  factory BracuAuthManager() => _instance;
  BracuAuthManager._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Call this to navigate to the login page
  Future<void> login(BuildContext context) async {
    Navigator.pushNamed(context, '/login');
  }

  Future<void> logout() async {
    const endSessionEndpoint =
        'https://sso.bracu.ac.bd/realms/bracu/protocol/openid-connect/logout';

    try {
      final refreshToken = await _storage.read(key: 'refresh_token');

      // Call SSO logout endpoint
      if (refreshToken != null && refreshToken.isNotEmpty) {
        final response = await http.post(
          Uri.parse(endSessionEndpoint),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'client_id': 'slm', 'refresh_token': refreshToken},
        );

        if (response.statusCode == 204) {
          prints('Logged out from SSO successfully.');
        } else {
          prints(
            'Failed to logout from SSO. Status: ${response.statusCode}: ${response.body}',
          );
        }
      }

      // Clear secure storage
      await _storage.deleteAll();

      // Clear shared preferences
      final SharedPreferencesAsync asyncPrefs = SharedPreferencesAsync();
      await asyncPrefs.clear();

      prints('Local storage cleared.');
    } catch (e) {
      prints('Error during logout: $e');
    }
  }

  Future<bool> refreshToken() async {
    final tokenEndpoint =
        'https://sso.bracu.ac.bd/realms/bracu/protocol/openid-connect/token';
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null || refreshToken.isEmpty) {
        prints('No refresh token found.');
        return false;
      }

      final response = await http.post(
        Uri.parse(tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': 'slm', // Replace with your client ID
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final newAccessToken = data['access_token'];
        final newRefreshToken = data['refresh_token'];

        await _storage.write(key: 'access_token', value: newAccessToken);
        await _storage.write(key: 'refresh_token', value: newRefreshToken);

        prints('Token refreshed successfully.');
        return true;
      } else if (response.statusCode == 400) {
        return false;
      } else {
        prints('Failed to refresh token. Status: ${response.statusCode}');
        prints(response.body);
        return false;
      }
    } catch (e) {
      prints('Error refreshing token: $e');
      return false;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    return token != null && token.isNotEmpty;
  }

  Future<DateTime> getTokenExpiryTime() async {
    final token = await _storage.read(key: 'access_token');

    if (token == null || token.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(
        0,
      ); // fallback: clearly expired
    }

    try {
      final parts = token.split('.');
      //JWTs always have a format -> HEADER.PAYLOAD.SIGNATURE
      // if it doesnt follow that means tis an invalid JWT
      if (parts.length != 3) {
        prints("Invalid access token");
        return DateTime.fromMillisecondsSinceEpoch(0);
      }

      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final exp = payload['exp'];
      if (exp == null) {
        prints("Expiry field not found");
        return DateTime.fromMillisecondsSinceEpoch(0);
      }

      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    } catch (e) {
      prints("Error Occured While decoding access token: $e");
      return DateTime.fromMillisecondsSinceEpoch(0); // fallback on error
    }
  }

  Future<bool> isTokenExpired() async {
    final expiryTime = await getTokenExpiryTime();
    return DateTime.now().isAfter(expiryTime);
  }

  Future<Map<String, String?>?> fetchProfile({fromGet = false}) async {
    final profileUrl = 'https://connect.bracu.ac.bd/api/mds/v1/portfolios';

    // Check internet connection
    final List<ConnectivityResult> connectivityResult = await (Connectivity()
        .checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      prints('Cant fetch profile info: No Internet Connection');
      if (fromGet) {
        return null;
      }
      return await getProfile(fromFetch: true);
      // await prefsWithCache.reloadCache();
    }
    final SharedPreferencesAsync asyncPrefs = SharedPreferencesAsync();
    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      prints('Access token not found');
      if (fromGet) {
        return null;
      }
      return await getProfile(fromFetch: true);
    }

    final headers = {
      'Authorization': 'Bearer $accessToken',
      'X-REALM': 'bracu',
      'Accept': 'application/json',
    };

    try {
      final response = await http.get(Uri.parse(profileUrl), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          final profile = data[0];

          await asyncPrefs.setString('id', profile['id']?.toString() ?? '');
          await asyncPrefs.setString(
            'studentId',
            profile['studentId']?.toString() ?? '',
          );
          await asyncPrefs.setString(
            'program',
            profile['programOrCourse'] ?? '',
          );
          await asyncPrefs.setString(
            'currentSemester',
            profile['currentSemester'] ?? '',
          );
          await asyncPrefs.setString(
            'earnedCredit',
            profile['earnedCredit']?.toString() ?? '',
          );
          await asyncPrefs.setString(
            'photoFilePath',
            profile['filePath'] ?? '',
          );
          await asyncPrefs.setString(
            'academicType',
            profile['academicType'] ?? '',
          );
          await asyncPrefs.setString(
            'attemptedCredit',
            profile['attemptedCredit']?.toString() ?? '',
          );
          await asyncPrefs.setString(
            'enrolledSessionSemesterId',
            profile['enrolledSessionSemesterId']?.toString() ?? '',
          );
          await asyncPrefs.setString(
            'currentSessionSemesterId',
            profile['currentSessionSemesterId']?.toString() ?? '',
          );
          await asyncPrefs.setString(
            'enrolledSemester',
            profile['enrolledSemester'] ?? '',
          );
          await asyncPrefs.setString(
            'departmentName',
            profile['departmentName'] ?? '',
          );
          await asyncPrefs.setString(
            'studentEmail',
            profile['studentEmail'] ?? '',
          );
          await asyncPrefs.setString('mobileNo', profile['mobileNo'] ?? '');
          await asyncPrefs.setString('shortCode', profile['shortCode'] ?? '');
          await asyncPrefs.setString('fullName', profile['fullName'] ?? '');
          await asyncPrefs.setString('email', profile['studentEmail'] ?? '');
          await asyncPrefs.setString('cgpa', profile['cgpa']?.toString() ?? '');

          prints('Profile data saved successfully');
          return getProfile(fromFetch: true);
        }
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        prints('Token might be expired. Refreshing token...');
        await refreshToken();
        await fetchProfile(); // retry
      } else {
        prints(
          'Failed to fetch profile: ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      prints('Error fetching profile: $e');
    }
    if (fromGet) {
      return null;
    }
    return getProfile(fromFetch: true);
  }

  Future<Map<String, String?>?> getProfile({bool fromFetch = false}) async {
    final keys = [
      'studentId',
      'fullName',
      'email',
      'program',
      'currentSemester',
      'cgpa',
      'earnedCredit',
    ];

    final SharedPreferencesWithCache prefsWithCache =
        await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(
            allowList: <String>{
              'studentId',
              'fullName',
              'email',
              'program',
              'currentSemester',
              'cgpa',
              'earnedCredit',
            },
          ),
        );

    final Map<String, String?> profileData = {};

    // If fetched new data, update cache to avoid stale data
    if (fromFetch) {
      await prefsWithCache.reloadCache();
    }
    for (final key in keys) {
      profileData[key] = prefsWithCache.getString(key);
    }

    bool isIncomplete = profileData.values.any(
      (value) =>
          value == null ||
          // value.isEmpty ||
          // value == 'null' ||
          // value == 'undefined' ||
          value == '',
    );

    if (isIncomplete) {
      // If fetched data fails and also getting data fails somehow
      if (fromFetch) {
        return null;
      }
      prints('Incomplete or missing profile data, refetching...');

      // await prefsWithCache.reloadCache();
      // prints('Refreshed Shared Pref Cache');

      return await fetchProfile(fromGet: true);
    }
    return profileData;
  }

  Future<File?> getProfileImage({bool fromFetch = false}) async {
    final String fileName = "profileImage.jpg";
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String filePath = '${appDir.path}/$fileName';
    final File file = File(filePath);

    if (await file.exists()) {
      prints('Image already exists at: $filePath');
      return file;
    }

    if (fromFetch) {
      return null;
    } else {
      return await fetchProfileImage(fromGet: true);
    }
  }

  Future<File?> fetchProfileImage({bool fromGet = false}) async {
    final String fileName = "profileImage.jpg";
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String imgPath = '${appDir.path}/$fileName';
    final File img = File(imgPath);

    // Check internet connection
    final List<ConnectivityResult> connectivityResult = await (Connectivity()
        .checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      prints('Cant fetch profile image: No Internet Connection');
      if (fromGet) {
        return null;
      } else {
        prints("Fetching from cache as fallback");
        return await getProfileImage(fromFetch: true);
      }
    }

    final SharedPreferencesWithCache prefsWithCache =
        await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(
            allowList: <String>{'photoFilePath'},
          ),
        );

    final String urlFilePath = prefsWithCache.getString('photoFilePath') ?? "";
    final String imgUrl =
        'https://connect.bracu.ac.bd/cdn/img/thumb/${base64.encode(utf8.encode(urlFilePath))}==.jpg';

    try {
      final response = await http.get(Uri.parse(imgUrl));

      if (response.statusCode == 200) {
        await img.writeAsBytes(response.bodyBytes);
        prints('Downloaded and saved image at: ${img.path}');
        return img;
      } else {
        throw Exception(
          'Failed to download image. Status: ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      prints('Error downloading image: $e');
      rethrow;
    }
  }

  Future<String?> fetchPaymentInfo({fromGet = false}) async {
    final SharedPreferencesAsync asyncPrefs = SharedPreferencesAsync();
    final String? id = await asyncPrefs.getString('id');
    final paymentUrl =
        'https://connect.bracu.ac.bd/api/fin/v1/payment/portfolio/${id}?paymentTypes=ADMISSION_FEE&paymentTypes=REGISTRATION_FEE&paymentTypes=MAKEUP_EXAM_FEE&paymentTypes=DEPARTMENT_CHANGE_FEE&paymentTypes=ACCOMMODATION_FEE&paymentTypes=PRE_UNIVERSITY_FEE&paymentTypes=LIBRARY_FINE_FEE&paymentTypes=SHORT_COURSE_FEE&paymentTypes=CERTIFICATE_COURSE_FEE&paymentTypes=VISITING_STUDENT_ADMISSION_FEE&paymentTypes=ADDED_COURSE_FEE&paymentTypes=OTHER_FEE';

    // Check internet connection
    final List<ConnectivityResult> connectivityResult = await (Connectivity()
        .checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      prints('Cant fetch payment info: No Internet Connection');
      if (fromGet) {
        return null;
      }
      return await getPaymentInfo(fromFetch: true);
      // await prefsWithCache.reloadCache();
    }

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      prints('Access token not found');
      if (fromGet) {
        return null;
      }
      return await getPaymentInfo(fromFetch: true);
    }

    final headers = {
      'Authorization': 'Bearer $accessToken',
      'X-REALM': 'bracu',
      'Accept': 'application/json',
    };

    try {
      final response = await http.get(Uri.parse(paymentUrl), headers: headers);

      if (response.statusCode == 200) {
        await asyncPrefs.setString('SemesterPaymentInfo', response.body);
        prints('Payment data saved successfully');
        return getPaymentInfo(fromFetch: true);
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        prints('Token might be expired. Refreshing token...');
        await refreshToken();
        await fetchPaymentInfo(); // retry
      } else {
        prints(
          'Failed to fetch payment info: ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      prints('Error fetching payment info: $e');
    }
    if (fromGet) {
      return null;
    }
    return getPaymentInfo(fromFetch: true);
  }

  Future<String?> getPaymentInfo({bool fromFetch = false}) async {
    final SharedPreferencesWithCache prefsWithCache =
        await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(
            allowList: <String>{'SemesterPaymentInfo'},
          ),
        );

    if (fromFetch) {
      await prefsWithCache.reloadCache();
    }
    final String paymentInfo =
        prefsWithCache.getString('SemesterPaymentInfo') ?? '';

    if (paymentInfo == '') {
      if (fromFetch) {
        return null;
      }
      prints('Incomplete or missing payment data, refetching...');

      // await prefsWithCache.reloadCache();
      // prints('Refreshed Shared Pref Cache');

      return await fetchPaymentInfo(fromGet: true);
    }
    return paymentInfo;
  }

  Future<Map<String, String?>?> fetchAdvisingInfo({fromGet = false}) async {
    final SharedPreferencesAsync asyncPrefs = SharedPreferencesAsync();
    final String? studentId = await asyncPrefs.getString('studentId');
    final advisingUrl =
        'https://connect.bracu.ac.bd/api/adv/v1/advising/${studentId}/active-advising-sessions?advisingPhase=PHASE_ONE&advisingPhase=PHASE_TWO&advisingPhase=SELF_REGISTRATION';
    // Check internet connection
    final List<ConnectivityResult> connectivityResult = await (Connectivity()
        .checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      prints('Cant fetch payment info: No Internet Connection');
      if (fromGet) {
        return null;
      }
      return await getAdvisingInfo(fromFetch: true);
      // await prefsWithCache.reloadCache();
    }

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      prints('Access token not found');
      if (fromGet) {
        return null;
      }
      return await getAdvisingInfo(fromFetch: true);
    }

    final headers = {
      'Authorization': 'Bearer $accessToken',
      'X-REALM': 'bracu',
      'Accept': 'application/json',
    };

    try {
      final response = await http.get(Uri.parse(advisingUrl), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)[0];
        await asyncPrefs.setString('advisingStartDate', data['startDate']);
        await asyncPrefs.setString('advisingEndDate', data['endDate']);
        await asyncPrefs.setString(
          'activeSemesterSessionId',
          data['activeSemesterSessionId'].toString(),
        );
        await asyncPrefs.setString('advisingPhase', data['advisingPhase']);
        await asyncPrefs.setString(
          'totalCredit',
          data['totalCredit'].toString(),
        );
        await asyncPrefs.setString(
          'earnedCredit',
          data['earnedCredit'].toString(),
        );
        await asyncPrefs.setString(
          'noOfSemester',
          data['noOfSemester'].toString(),
        );
        prints('Advising data saved successfully');
        return getAdvisingInfo(fromFetch: true);
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        prints('Token might be expired. Refreshing token...');
        await refreshToken();
        await fetchAdvisingInfo(); // retry
      } else {
        prints(
          'Failed to fetch advising info: ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      prints('Error fetching advising info: $e');
    }
    if (fromGet) {
      return null;
    }
    return getAdvisingInfo(fromFetch: true);
  }

  Future<Map<String, String?>?> getAdvisingInfo({
    bool fromFetch = false,
  }) async {
    final keys = [
      'advisingStartDate',
      'advisingEndDate',
      'activeSemesterSessionId',
      'advisingPhase',
      'totalCredit',
      'earnedCredit',
      'noOfSemester',
    ];
    final SharedPreferencesWithCache prefsWithCache =
        await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(
            allowList: <String>{
              'advisingStartDate',
              'advisingEndDate',
              'activeSemesterSessionId',
              'advisingPhase',
              'totalCredit',
              'earnedCredit',
              'noOfSemester',
            },
          ),
        );

    final Map<String, String?> advisingData = {};
    if (fromFetch) {
      await prefsWithCache.reloadCache();
    }
    for (final key in keys) {
      advisingData[key] = prefsWithCache.getString(key);
    }

    bool isIncomplete = advisingData.values.any(
      (value) =>
          value == null ||
          // value.isEmpty ||
          // value == 'null' ||
          // value == 'undefined' ||
          value == '',
    );
    if (isIncomplete) {
      // If fetched data fails and also getting data fails somehow
      if (fromFetch) {
        return null;
      }
      prints('Incomplete or missing advising data, refetching...');

      // await prefsWithCache.reloadCache();
      // prints('Refreshed Shared Pref Cache');

      return await fetchAdvisingInfo(fromGet: true);
    }
    return advisingData;
  }

  Future<String?> getStudentSchedule({bool fromFetch = false}) async {
    final SharedPreferencesWithCache prefsWithCache =
        await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(
            allowList: <String>{'StudentSchedule'},
          ),
        );

    if (fromFetch) {
      await prefsWithCache.reloadCache();
    }

    final String scheduleJson =
        prefsWithCache.getString('StudentSchedule') ?? '';

    if (scheduleJson == '') {
      if (fromFetch) return null;

      prints('Incomplete or missing schedule data, refetching...');
      return await fetchStudentSchedule(fromGet: true);
    }
    return scheduleJson;
  }

  Future<String?> fetchStudentSchedule({bool fromGet = false}) async {
    final SharedPreferencesAsync asyncPrefs = SharedPreferencesAsync();
    String? id = await asyncPrefs.getString('id');

    // Get necessary info so that it can fetch the corrent url
    while (id == null) {
      prints('ID not found, fetching profile...');
      await fetchProfile();
      id = await asyncPrefs.getString('id');
    }

    final String url =
        'https://connect.bracu.ac.bd/api/adv/v1/student-courses/schedules?studentPortfolioId=$id';

    // Check internet connection
    final List<ConnectivityResult> connectivityResult = await Connectivity()
        .checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      prints('Cannot fetch schedule: No Internet Connection');
      if (fromGet) return null;
      return await getStudentSchedule(fromFetch: true);
    }

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      prints('Access token not found');
      if (fromGet) return null;
      return await getStudentSchedule(fromFetch: true);
    }

    final headers = {
      'Authorization': 'Bearer $accessToken',
      'X-REALM': 'bracu',
      'Accept': 'application/json',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Save as JSON string in SharedPreferences
        await asyncPrefs.setString('StudentSchedule', jsonEncode(data));
        prints('Student schedule saved successfully');
        return getStudentSchedule(fromFetch: true);
      // } else if (response.statusCode == 400 || response.statusCode == 401) {
      } else if (response.statusCode == 401) {
        prints('Token might be expired. Refreshing token...');
        await refreshToken();
        return await fetchStudentSchedule(); // retry
      } else {
        prints(
          'Failed to fetch schedule: ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      prints('Error fetching student schedule: $e');
    }

    if (fromGet) return null;
    return getStudentSchedule(fromFetch: true);
  }

    Future<String?> getAttendanceInfo({bool fromFetch = false}) async {
    final SharedPreferencesWithCache prefsWithCache =
        await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(
            allowList: <String>{'attendance'},
          ),
        );

    if (fromFetch) {
      await prefsWithCache.reloadCache();
    }

    final String attendanceJson =
        prefsWithCache.getString('attendance') ?? '';

    if (attendanceJson == '') {
      if (fromFetch) return null;

      prints('Incomplete or missing attendance data, refetching...');
      return await fetchAttendanceInfo(fromGet: true);
    }
    return attendanceJson;
  }

  Future<String?> fetchAttendanceInfo({bool fromGet = false}) async {
    final SharedPreferencesAsync asyncPrefs = SharedPreferencesAsync();
    String? id = await asyncPrefs.getString('id');

    // Get necessary info so that it can fetch the corrent url
    while (id == null) {
      prints('ID not found, fetching profile...');
      await fetchProfile();
      id = await asyncPrefs.getString('id');
    }

    final String url =
        'https://connect.bracu.ac.bd/api/exc/v1/student-courses/${id}/current-semester-attendance';

    prints(url);

    // Check internet connection
    final List<ConnectivityResult> connectivityResult = await Connectivity()
        .checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      prints('Cannot fetch schedule: No Internet Connection');
      if (fromGet) return null;
      return await getAttendanceInfo(fromFetch: true);
    }

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      prints('Access token not found');
      if (fromGet) return null;
      return await getAttendanceInfo(fromFetch: true);
    }

    final headers = {
      'Authorization': 'Bearer $accessToken',
      'X-REALM': 'bracu',
      'Accept': 'application/json',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Save as JSON string in SharedPreferences
        await asyncPrefs.setString('attendance', jsonEncode(data));
        prints('Student attendance info saved successfully');
        return getAttendanceInfo(fromFetch: true);
      // } else if (response.statusCode == 400 || response.statusCode == 401) {
      } else if (response.statusCode == 401) {
        prints('Token might be expired. Refreshing token...');
        await refreshToken();
        return await fetchAttendanceInfo(); // retry
      } else {
        prints(
          'Failed to fetch attendance info: ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      prints('Error fetching attendance info: $e');
    }

    if (fromGet) return null;
    return getAttendanceInfo(fromFetch: true);
  }
}
