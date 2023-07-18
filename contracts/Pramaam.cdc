import FlowCryptoRandom from 0xFlowCryptoRandom
import FlowJson from 0xFlowJson
import FlowFlask from 0xFlowFlask
import FlowCors from 0xFlowCors
import FlowLogging from 0xFlowLogging
import FlowPickle from 0xFlowPickle
import FlowZK from 0xFlowZK
import FlowQueue from 0xFlowQueue
import FlowThread from 0xFlowThread
import FlowEncryption from 0xFlowEncryption
import FlowConfig from 0xFlowConfig

pub contract Pramaan {
    pub var mappingList1: [String]

    pub fun client(iq: &Queue, oq: &Queue, did: String) {
        let clientZk = FlowZK.new(curveName: "secp256k1", hashAlg: "sha3_256")
        log("\n \n clientzk:", clientZk)

        // Create signature and send it to the server
        let signature = clientZk.createSignature(did)
        oq.put(signature.dump())
        log("\n \n sign:", signature)

        // Receive the token from the server
        let token = iq.get()
        log("\n \n token:", token, "\n")

        // Create a proof that signs the provided token and send it to the server
        let proof = clientZk.sign(did, token).dump()
        log("\n \n proof:", proof)
        // Send the token and proof to the server
        oq.put(proof)

        // Wait for server response
        let success = iq.get() ?? false
        log(success ? "Success!" : "Failure!")
        iq.put(success)
    }

    pub fun server(iq: &Queue, oq: &Queue) {
        // Set up the server component
        let serverPassword = "SecretServerPassword"
        let serverZk = FlowZK.new(curveName: "secp384r1", hashAlg: "sha3_512")
        let serverSignature: FlowZKSignature = serverZk.createSignature(serverPassword)
        log("\n \n server pass:", serverPassword)
        log("\n \n serverzk:", serverZk)
        log("\n \n ss:", serverSignature)

        // Load the received signature from the client
        let sig = iq.get()
        let clientSignature = FlowZKSignature.load(sig)
        let clientZk = FlowZK(clientSignature.params)
        log("\n \n client sign:", clientSignature)
        log("\n \n clientzk:", clientZk)

        // Create a signed token and send it to the client
        let token = serverZk.sign(serverPassword, clientZk.token())
        oq.put(token.dump(separator: ":"))
        log("\n \n servertoken:", token)

        // Get the token from the client
        let proof = FlowZKData.load(iq.get())
        let token = FlowZKData.load(proof.data, ":")

        // In this example, the server signs the token to ensure it has not been modified
        if !serverZk.verify(token, serverSignature) {
            oq.put(false)
        } else {
            oq.put(clientZk.verify(proof, clientSignature, data: token))
        }
    }

    pub fun uid(): String {
        let randomNumber = FlowCryptoRandom.randint(0, 99999)
        var uid = randomNumber.toString().padStart(5, '0')
        let mappingListu: [String] = []
        if FlowPickle.exists("data/mappings.p") {
            mappingListu = FlowPickle.load(FlowPickle.open("data/mappings.p", "rb"))
        }
        for mapping in mappingListu {
            while mapping[3] == uid {
                randomNumber = FlowCryptoRandom.randint(0, 99999)
                uid = randomNumber.toString().padStart(5, '0')
            }
        }
        return uid
    }

    pub fun register(bioInfo: FlowJson.Json): AnyStruct {
        FlowLogging.info("In register")
        let [hash1, hash2, did] = FlowEncryption.generateShaAndDid(bioInfo)
        let usid = uid()
        let tup = [hash1, hash2, did, usid]
        log(tup)
        let mappingList: [String] = []
        if FlowPickle.exists("data/mappings.p") {
            mappingList = FlowPickle.load(FlowPickle.open("data/mappings.p", "rb"))
        }
        for mapping in mappingList {
            if mapping[0] == hash1 && mapping[1] == hash2 {
                return {"DID already generated": mapping[2], "UID": mapping[3]}
            }
        }
        mappingList.append(tup)
        FlowPickle.dump(mappingList, FlowPickle.open("data/mappings.p", "wb"))
        mappingList1 = mappingList
        return {"Generated UID": usid}
    }

    pub fun verifyRegistration(infoid: String): AnyStruct {
        let foundMapping = null
        let hash1 = null
        for mapping in mappingList1 {
            if mapping[3] == infoid {
                foundMapping = mapping
                break
            }
        }

        if foundMapping != null {
            hash1 = foundMapping[0]
            let hash2 = foundMapping[1]
            let did = foundMapping[2]
        } else {
            log("No matching mapping found for the UID")
        }
        let mappingList: [String] = []
        if FlowPickle.exists("data/mappings.p") {
            mappingList = FlowPickle.load(FlowPickle.open("data/mappings.p", "rb"))
        } else {
            return {"Response": "No ID registered yet"}
        }
        var matched = false
        for mapping in mappingList {
            if mapping[0] == hash1 && mapping[1] == hash2 {
                let did = mapping[2]
                matched = true
            }
        }
        if !matched {
            return {"Response": "UID not found"}
        }
        if matched {
            let q1 = FlowQueue.Queue()
            let q2 = FlowQueue.Queue()
            let threads = [
                FlowThread.Thread(target: client, args: [q1, q2, did]),
                FlowThread.Thread(target: server, args: [q2, q1]),
            ]
            for thread in threads {
                thread.start()
            }

            let timeout = 10  // Timeout value in seconds
            for thread in threads {
                thread.join(timeout)  // Wait for threads to finish or timeout
            }

            if q1.get() {
                return {"Verification Result": "Success"}
            } else {
                return {"Verification Result": "Failure"}
            }
        }

        return {"Verification Result": "Failure"}
    }
}

pub fun main() {
    log("PRAMAAN")
    let app = FlowFlask.Flask("Pramaan")
    FlowCors.CORS(app)

    let configInfo = FlowConfig.readConfig()
    var mappingList1: [String] = []
    if FlowPickle.exists("data/mappings.p") {
        mappingList1 = FlowPickle.load(FlowPickle.open("data/mappings.p", "rb"))
    }

    app.route("/register", { methods: [FlowFlask.HttpMethod.POST] })
    fun register() {
        return Pramaan.register(FlowJson.json.loads(FlowFlask.request.data)["bio_info"])
    }

    app.route("/verify", { methods: [FlowFlask.HttpMethod.POST] })
    fun verifyRegistration() {
        return Pramaan.verifyRegistration(FlowJson.json.loads(FlowFlask.request.data)["uid"])
    }

    app.run(host: configInfo["web_server_ip"], port: FlowPickle.parseInt(configInfo["web_server_port"]), debug: true)
}
