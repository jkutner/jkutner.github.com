---
layout: post
title:  "Integrating Firebase with Heroku to Send Custom Notifications"
date:   2017-03-13 10:01:00
---

Google's Firebase Realtime Database makes a great backend for mobile apps. It
can sync data across clients in realtime, and remains available when your app goes offline.

You can combine this powerful service with Heroku to build custom apps that
execute business logic such as sending notifications or integrating with other systems.
In this post, you'll learn how to combine a Firebase database with a
Heroku app to send email notifications when certain types of events occur.

## Creating a Firebase Database

If you don't already have a Firebase project,
open the [Firebase console](https://console.firebase.google.com) and
select **Create a New Project**.

You'll also need a "Service Account" for your project, which you can create by
clicking the Settings icon (⚙) in the navigation menu and selecting **Permissions**.
Then select **Service Accounts** and click the **Create service account** button.
Give the account a name, and assign it the **Service account actor** role.

After the account has been created, you'll need to download the JSON-formated private key
for the account.
Select the **...** link next to the account, and click **Create key**. Choose JSON as the
file format, and download the file.

Put the JSON file somewhere safe. You'll need it in the next step.

## Creating a Heroku App

Creating a Heroku app is simple. Click the button below to deploy my
[Firebase database quickstart application](https://github.com/kissaten/firebase-database-quickstart)
to integrate with your Firebase project.
When you are prompted for a `SERVICE_ACCOUNT_JSON` field, copy and paste the contents of
the JSON file you downloaded earlier.

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.png)](https://dashboard.heroku.com/new?button-url=https%3A%2F%2Fgithub.com%2Fkissaten%2Ffirebase-database-quickstart&template=https%3A%2F%2Fgithub.com%2Fkissaten%2Ffirebase-database-quickstart)

The app is provisioned with a [SparkPost](https://elements.heroku.com/addons/sparkpost)
add-on that provides an STMP server for sending emails.

The app code contains models that represent users and posts (like tweets).
It also includes a dependency on the Google Firebase Java SDK, which is
configured in the `build.gradle` with this entry:

```ruby
compile 'com.google.firebase:firebase-admin:4.1.1'
```

The app uses the SDK to register listeners on the Firebase database that respond to
events. For example this listener responds to new "stars" on a post:

```java
private static void addNewStarsListener(final DatabaseReference postRef, final Post post) {
  postRef.child("stars").addChildEventListener(new ChildEventListener() {
    public void onChildAdded(DataSnapshot dataSnapshot, String prevChildName) {
      // New star added, notify the author of the post
      sendNotificationToUser(post.uid, postRef.getKey());
    }
    //...
  });
}
```

The `sendNotificationToUser` sends an email to the user via the SparkPost add-on.
The code for this can be found in the [`MyEmailer`](https://github.com/kissaten/firebase-database-quickstart/blob/master/src/main/java/com/google/firebase/quickstart/email/MyEmailer.java) class.

To trigger this listener, you'll need to create a new post and add a star to it.

## Triggering Events from an Android App

Clone my sample [Firebase database quickstart Android app](https://github.com/jkutner/firebase-quickstart-android-database)
and open it in Android Studio.

```sh-session
$ git clone https://github.com/jkutner/firebase-quickstart-android-database
```

Then connect Android Studio to Firebase by selecting "Tools -> Firebase"
and open the "Assistant" window. Click Database feature, and
then click the "Connect to Firebase" button to connect to Firebase, which will
add the necessary code to your app.

Return the [Firebase console](Firebase Console) for your project and select
the "Authentication" tab. Then select the "Sign-In Method" tab and choose to
enable "Email/Password" authentication.

Now return to Android Studio, and run the sample app on an emulator or device.

When prompted, select "Sign Up" to create a new account using your email
address. You can confirm the account was created by checking your Firebase project
dashboard.

Finally, create a new post in the app and click the star button for it.
In a moment, you'll receive an email notifying you of the event.

<img src="https://github.com/jkutner/firebase-quickstart-android-database/raw/master/app/src/screen.png" style="width: 40%; margin-left: 0; margin-right: 0" alt="Database App">

You can use this same pattern to integrate Firebase with [Heroku Kafka](https://elements.heroku.com/addons/heroku-kafka),
[Heroku Postgres](https://elements.heroku.com/addons/heroku-postgresql), or a webapp based on the [Firebase JS template](https://github.com/firebase/quickstart-js).

For more information on using Google's Firebase services, see the
[Google Firebase documentation](https://firebase.google.com/docs/database/).

To learn more about deploying custom application on Heroku, see the
[Getting Started with Gradle on Heroku](https://devcenter.heroku.com/articles/getting-started-with-gradle-on-heroku#introduction)
guide.
