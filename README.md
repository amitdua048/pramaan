# Pramaan: A Secure Identity Verification Protocol Overview
Pramaan is a security-focused codebase developed in Cadence for identity verification purposes. The code uses cryptography and zero-knowledge proof to ensure the identity of a registered user securely. The main objective of this code is to generate a unique identity (UID) for a user based on the provided biometric information and to verify the given UID.

# Dependencies
The code imports several dependencies:

FlowCryptoRandom : Provides functions for generating random numbers
FlowJson : Provides functions for JSON operations
FlowFlask : A web microframework
FlowCors : CORS middleware
FlowLogging : For logging
FlowPickle : To pickle (serialize and deserialize) Python objects
FlowZK : To perform Zero-Knowledge proofs
FlowQueue : Implements queues for asynchronous communication
FlowThread : Handles threads
FlowEncryption : Encryption-related functionalities
FlowConfig : To manage configuration data
Contract: Pramaan
The contract Pramaan consists of several functions:

# Variables:
mappingList1: This variable stores the mapping list which contains the hash, digital id (DID), and the unique id (UID) of each user.

# Functions:
## client(iq: &Queue, oq: &Queue, did: String)
The client function takes input and output queues and a digital id (DID) as arguments. It generates the client's zero-knowledge proof and handles the communication with the server using these queues.

## server(iq: &Queue, oq: &Queue)
The server function also takes input and output queues as arguments. It's responsible for generating server's zero-knowledge proof and verifying the proofs coming from the client.

## uid(): String
The uid function generates a unique id (UID) for each user. It ensures that the UID is unique and not currently in use.

## register(bioInfo: FlowJson.Json): AnyStruct
The register function takes a user's biometric information as input, then generates SHA hashes and a DID for the user, and maps these to a new UID. The function returns the newly generated UID.

## verifyRegistration(infoid: String): AnyStruct
The verifyRegistration function takes a UID as input, then finds the associated hashes and DID and verifies the UID using the client and server functions. It returns the verification result.

# Main Function
The main function sets up the Flask application and CORS, reads the configuration data, loads the mapping list, and sets up the "/register" and "/verify" routes. The Flask application is run using the IP address and port from the configuration data.

## Usage
Use the /register endpoint to register a new user by sending a POST request with the user's biometric information in the bio_info field of the request data.
Use the /verify endpoint to verify a registered user's UID by sending a POST request with the UID in the uid field of the request data.

# Demo video on Youtube
Pramaan : ZKP based Decentralisation authentication: Product Demo
https://www.youtube.com/watch?v=hIcd4nvLZuE 

# Conclusion
This codebase presents a secure, practical solution for identity verification. Its implementation of cryptography and zero-knowledge proofs enables strong security for user identities.
