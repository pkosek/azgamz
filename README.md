[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fpkosek%2Fazgamz%2Fmaster%2Fazuredeploy.json)

## Instructions
1. Deploy
2. Log in via RDP, login to steam and install games
3. Disconnect RDP session via the 'Disconnect' link on the dektop
4. Launch steam on your end and Play!
5. Shutdown the VM - make sure it's deallocated (stopped) to avoid extra charges (automated shutdowns are good idea)
6. Next time you play, just start the VM via the portal (shell), no need to RDP again.

## FAQ
- Moonlight Streaming is not supported as it requires GeForce card (not Tesla)

## Resources
- Steam Remote Play: https://support.steampowered.com/kb_article.php?ref=3629-riav-1617
- This is a loose fork of https://github.com/ecalder6/azure-gaming/ - Thank you!
- AWS Alternative with RTX cards: https://github.com/parsec-cloud/Parsec-Cloud-Preparation-Tool