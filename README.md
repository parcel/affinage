A quick express app that grabs data from Stripe, then displays it.

There are different plot lines for all customers, trial customers, and paying customers.

## Usage:
Put your stripe api token in the STRIPE_KEY env variable.

`npm install` to fetch dependencies, then `npm run start`

Server runs on port `8082` by default.

## Developing:
`npm install -g nodemon` to get `nodemon`, which will restart the server every time you make a change.

`npm run dev` to start the server using nodemon and also a process that watches the client directory for `.coffee` changes and compiles them.

## TODO:

- Extract auth credentials to config file
- Extract STRIPE_KEY to config file (with possibility to still use ENV variable)