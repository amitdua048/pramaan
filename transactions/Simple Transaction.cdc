import Pramaan from "../contracts/Pramaan.cdc"

transaction {
    prepare(signer: AuthAccount) {
        // if the account doesn't already have a collection
        if signer.borrow<&Pramaan.Collection>(from: Pramaan.CollectionStoragePath) == nil {

            // create a new empty collection
            let collection <- Pramaan.createEmptyCollection()

            // save it to the account
            signer.save(<-collection, to: Pramaan.CollectionStoragePath)

            // create a public capability for the collection
            signer.link<&Pramaan.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(Pramaan.CollectionPublicPath, target: Pramaan.CollectionStoragePath)
        }
    }
}