- create func for getting how must semester left bar
- create page for useful links
- refactor code again so that fetchers on only fetch and getters only get
- improve friend schedule handling

Refresh token
if refresh token exxpired go back to login
if not refresh token

If there is no internet connection, it will give a breadcrumb saying so

WOrk needs to be done for refreshToken
check for error codes when refresh token is expired
make refresh button show some feedback, for e.g no internet, need to login in, etc
Why does info refresh / data doesnt cache when token expires?

If i dont find an access_token in Shared pref, should i just get data from cache (current behaviour)
or 
should i grab a new token to login?

format bracuauth manager better

dont return null from bracu auth manager, but instead return the error in the map

for e.g:

    return {"error": e.toString()};

so then when calling we can use 

  if (advisingData.containsKey("error")) {
and put that in a snackbar

create model classes for data in fetched from api so that we dont need to remember what fields is spits out


improve friend schedule handling

get all classes in a particular day, for all friends
sort by timing

get the current time


if the current time is within class start and end time, show in class

if the current time is after class, and there is no class that day, show no class today

if the current time is after class, and there is a class, check the gap
if the gap between the classe them is less than 30 min, skip to the next class end time
if the gap is more than 30 min, show the gap time - current time

if the current time is before class, show how many hrs and min before class
if already one class done, check for another class

