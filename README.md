# fuel-loup
iOS Udacity capstone project

-- Idea

FuelLoup app finds electric vehicle (ev) stations located around user and displays it on the map. Ev stations are gathered basing on the current user location (longitude and latidue values). It also shows a list of these ev stations with an approximate distance from user location to each ev station.

- The screens

1. Main screen

 The app presents two tabs:
* map view with the Ev stations localized in the area of 5 km
* List of the same ev stations with an approximate distance from user location 

In the navigation bar on the right there is map settings (3) and favorites options (4).

Tapping on the ev station icon in the map opens an info view with basic information about the selected ev station (name, address). User can tap on the "Details" button and be redirected to the ev station details screen (2).
Tapping on the ev station row in the list on the second tab also redirects to ev station details screen (2).

2. Ev station details screen

It displays all the information about ev station:
* name, address, phone
* available connectors (name, type and power they provide)
* button for adding the ev station to favorites
* if ev station is already added to Favorites the button presents "Remove from Favorites" option and action
* button for launching system map application (Google or Apple) and displaying route to the ev station

3. Map settings screen

The screen is for selecting map type - should it be the default Apple map displayed or maybe user wants it to have a black/white overlay on the map. The choice is saved in UserDefaults storage so next app launch remembers which map to show.

4. Favorites screen

If user taps on "Add to favorites" button in details screen (2) the selected ev station is saved in database (using CoreData interface). Next, if user taps on Favorites option in the navigation bar he is redirected to Favorites screen displaying a list of favorite ev stations. The list shows basic information about the ev station exactly in the same way as the screen in list tab does.


