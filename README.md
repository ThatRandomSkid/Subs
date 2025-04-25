# Subs
Simple API interface to find a YouTube user's subscription, based on YouTube's API

Only works if the target user has made their subscriptions public, which is off by default for newer accounts but on for many older ones.


To use:
1. Download and navigate to file location
2. Replace the API key placeholder with your own Google Cloud YouTube Data API v3 key
3. To initilze script, run in CLI: chmod +x subs.sh
4. To run the script, run in CLI: ./subs.sh "target_username"

Optional: Add 'adv' after to get a description of the subscribed channels and when the user subscribed.
