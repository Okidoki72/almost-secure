basic chat app with e2e encryption

interesting bits:

- on ios most data (signal stores, messages) is stored in sqlite encrypted with sqlcipher, the passphrase is stored on keychain
- private signal keys are also stored on keychain
- on the backend, elixir is used to relay public keys and encrypted messages between users

---

Backend

[![Build Status](https://semaphoreci.com/api/v1/syfgkjasdkn/almost-secure/branches/master/shields_badge.svg)](https://semaphoreci.com/syfgkjasdkn/almost-secure)

---

iOS

[![Build Status](https://travis-ci.org/syfgkjasdkn/almost-secure.svg?branch=master)](https://travis-ci.org/syfgkjasdkn/almost-secure)
