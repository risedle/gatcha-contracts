## SocioCat Claim

### Deploy

1. Setup `.env`

    ```
    # Deployer private key
    PRIVATE_KEY=
    # Signer wallet to sign the claim signature
    SIGNER=
    # Cat token to claim
    TOKEN=
    # Contract owner that can modify `signer`
    OWNER=


    # Additional

    RPC_URL=
    ETHERSCAN_API_KEY=
    ```

2. Run deploy script

    ```shell
    $ forge script ./script/SocioCatClaim.s.sol \
    --rpc-url $RPC_URL \ 
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY
    ```
