# ADCK

a gem for the Apple Push Notification Service (APNS).

Based on the [APNS](https://github.com/jpoz/apns) gem by [James Pozdena](https://github.com/jpoz) \<<jpoz@jpoz.net>>

## Install

    gem install adck

or in your Gemfile:

    gem 'adck'

## Setup

You need to have your certificate in the form aof a .pem. If you have yours as a p12 you can run this to convert it:

	openssl pkcs12 -in cert.p12 -out cert.pem -nodes -clcerts

### Defaults

You can set the defaults for all connections created by setting them on the `ADCK` object.

	ADCK.host = 'gateway.push.apple.com'
	ADCK.pem  = '/path/to/pem/file'
	ADCK.port = 2195 # default, doesn't need to be set

## Examples

### Quick send one notification

	device_token = '123abc456def'

	ADCK(device_token, 'POPUP!')

is equivalent to

	ADCK.send_notification(device_token, 'POPUP!')

also the same

	ADCK.send_notification(device_token, body: 'POPUP!')

All of these quick sendings use the default server values and open and close the connection for each notification.

### Multiple notifications

Behind the scenes on the single notifications it creates a notification object

	n1 = ADCK::Notification.new(device_token, 'POPUP!)

`Notification` is a combination of a `Message` and a device token.

The `Message` creates the payload which is sent to the iPhone.

To send many messages quickly

	n2 = ADCK::Notification.new(device_token, 'POPUP2!)

	ADCK.send_notifications([n1,n2])

or you can

	ADCK([n1,n2])

#### Message

A message is just the payload seperated withouat an identifier to send it to the phone. It can take all the options that Apple supports:

* `alert` - The actual message being sent
* `badge` - The number to set the badge count to
* `sound` - Sound to play for notification

The alert property is special and allows for other fields, in place of alert you can pass:

* `body` - the text to display
* `action_loc_key` - Localized key for what to set the action button on the notification to
* `loc_key` - localized message key, in place of the body you can pass the key from one of your localized plists
* `loc_args` - if you pass a loc_key you must pass an array to loc_args for what values to fill into the localized arry
* `launch_image` - the image to display while launching instead of the default one

For more details on how these values work plase refer to [Apple's Documentation](http://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/ApplePushService/ApplePushService.html)

#### Creating a message

Messages are passed all the way though so in the previous example where we ran `ADCK(token, 'POPUP!')` it at some point ran `Message.new(body: 'POPUP!')`.

Here are some examples of messages:

	ADCK::Message.new(body: 'This is what the user sees')

Now lets add a sound and a badge count:

	ADCK::Message.new(body: 'This is what the user sees', sound: 'default', badge: 5)

What if we don't want to show an action button, just want to pop up a notification with an "OK" button.

	ADCK::Message.new(body: 'Something you cant do anything about', action_loc_key: nil)

#### Sending one message to many people

The most performant way to send the same message to a lot of people is to make a message and then pass it an array of tokens to send to.

	m = ADCK::Message.new(body: 'Cute Kitty!', action_loc_key: "PET_IT")
	m.send_to([token1,token2,…,tokenN])

This will open and close a new connection to the server. If you want to use an existing connection you can set it on the message

	conn = ADCK::Connection.new
	m.connection = conn

	conn.open
	m.send_to([token1,token2,…,tokenN])
	m.send_to([token1,token2,…,tokenN])
	conn.close


There's one caviat, the message is compiled and frozen upon sending to improve performance. This is primarily an issue when sending badge numbers. I'm working on creating a performant way to send out large numbers of badge updates.

	m = ADCK::Message.new(body: 'Cute Kitty!', action_loc_key: "PET_IT")
	m.send_to([token1,token2,…,tokenN])
	m.body = 'Cute Kitty2' #=> RuntimeError: can't modify frozen ADCK::Message

You can however dupe

	m = m.dup
	m.body = 'Cute Kitty2'
	m.send_to([token1,token2,…,tokenN])

or you can tell the message to not freeze it

	m = ADCK::Message.new(body: 'Cute Kitty!', action_loc_key: "PET_IT", freeze: false)
	m.send_to([token1,token2,…,tokenN])
	m.body = 'Cute Kitty2'
	m.send_to([token1,token2,…,tokenN])

#### Extra parameters

* freeze: if set to false the message wont be frozen when packaged up
* validate: disable valdation of size and other values
* truncate: Truncate the value of `body` if it would cause the message to be too
large

### Connection

A good example of when you'd want to use multiple connections is if you have different `.pem` files (for different apps maybe) that you want to use.

	conn_iphone = ADCK::Connection.new(pem: Rails.root+'config/pem/iphone.pem')
	conn_ipad = ADCK::Connection.new(pem: Rails.root+'config/pem/ipad.pem')

	n = ADCK::Notification.new(token, "Sent to both iPhone and iPad apps")
	n2 = ADCK::Notification.new(token2, "Sent to iPad app")

	conn_iphone.send_notification(n)
	conn_ipad.send_notifications([n,n2])