# Secure Pet Shelter Demo

This is a demonstration using CyberArk Conjur and openssl to secure both ends of
a Kafka data stream. Only encrypted data is stored in Kafka; producers and
consumers access the plaintext data stream by authenticating with Conjur,
fetching an encryption key, and using openssl to handle the data stream.

## Getting started

First, you'll need these prerequisites:

1) Docker CE
2) a terminal application
3) git
4) openssl

Next, clone this repository and run `bin/start`. This starts all necessary
services:
* Conjur open source
* Postgres
* Kafka
* Zookeeper

It also stores a 256-bit encryption key in Conjur and loads a Conjur Machine
Authorization Markup Language (MAML) security policy allowing our hypothetical
users to fetch it.

### Introducing our hypothetical users
**Alice** is the pet shelter's sysadmin. She has the ability to fetch and update
Kafka encryption keys, create new keys for new Kafka topics, and generally
administrate the Kafka security policy. She is responsible for protecting the
sensitive information which gets persisted to disk within the shelter's
infrastructure.

**Bob** is a local newspaper reporter. Alice permits him via Conjur security policy
to fetch the Kafka encryption key for the "pets" topic, allowing him access to
data that's crucial for his reporting and the shelter's mission.

### Welcoming animals to the shelter (populating Kafka)

To populate the Kafka stream, use `bin/run-shelter`. Alice runs this in Docker
using her credentials. (If she wanted to run it in the cloud, she could assign
it its own distinct machine identity using Conjur MAML policy.)

First, the app establishes connetions to Conjur and Kafka. It uses the Conjur
API to fetch the encryption key, then each time an animal is accepted to the
shelter it uses that key to send an encrypted message to Kafka.

### Reporting on adoptable animals (reading the Kafka stream)

To read the Kafka data stream in its raw form, you can run `bin/dump-messages`.
This uses the "Kafka CLI consumer" app included in Kafka upstream. On doing so,
you will notice that the messages are illegible: they have been encrypted and
also base64-encoded.

In order for our hypothetical reporter Bob to read the cleartext stream, he uses
`bin/run-reporter`. This app runs in Docker using Bob's credentials. When he
fetches the encryption key, Conjur authenticates his request, authorizes his
access to the specific key for that topic, and writes an audit record indicating
which topic he accessed.
