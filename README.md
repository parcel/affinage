![](https://www.evernote.com/shard/s24/sh/d6948511-25f2-4fd0-a3c3-e6ef5b04644c/42cbcf4e7dc6798e1d6a2b9d6107ed8a/deep/0/Screen-Shot-2014-08-28-at-11.27.26-AM.png)

A quick express app that grabs data from Stripe, then displays it.

There are different plot lines for all customers, trial customers, and paying customers.

## Usage
Update config.json with your credentials. You can also use env variables.

`npm install` to fetch dependencies, then `npm run start`

Server runs on port `8082` by default.

## Developing
`npm install -g nodemon` to get `nodemon`, which will restart the server every time you make a change.

`npm run dev` to start the server using nodemon and also a process that watches the client directory for `.coffee` changes and compiles them.
