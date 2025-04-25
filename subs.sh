#!/bin/bash

# --- Check if an argument (channel name) was provided ---
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 \"Channel Name\""
  echo "Example: $0 \"Not David\""
  echo "Use 'adv' at end for more indepth anaylasis"
  echo "Note: Put the channel name in quotes if it contains spaces."
  exit 1 # Exit with an error code
fi

# --- Configuration ---
# IMPORTANT: Replace with your actual API key.
# Best practice: Store this as an environment variable instead of hardcoding.
# Example: export YOUTUBE_API_KEY="YOUR_KEY" then use "${YOUTUBE_API_KEY}" below.
API_KEY="YOUR_API_KEY_HERE"

# Get the channel name from the first command-line argument
CHANNEL_NAME="$1"
MODE="$2"

# --- URL Encode the Channel Name ---
# Requires jq to be installed
ENCODED_CHANNEL_NAME=$(jq -sRr @uri <<< "$CHANNEL_NAME")

echo "Searching for channel: '$CHANNEL_NAME' (Encoded: $ENCODED_CHANNEL_NAME)" >&2 # Send status messages to stderr

# --- 1. Search for the channel and extract its ID ---
SEARCH_URL="https://www.googleapis.com/youtube/v3/search?part=snippet&type=channel&maxResults=1&key=${API_KEY}&q=${ENCODED_CHANNEL_NAME}"

CHANNEL_ID=$(curl -s "$SEARCH_URL" | jq -r '.items[0].id.channelId // empty')

# --- Check if a Channel ID was actually found ---
if [[ -z "$CHANNEL_ID" ]]; then
  echo "Error: Could not find Channel ID for '$CHANNEL_NAME'. Please check the name or API key." >&2
  exit 2 # Exit the script if no ID was found
fi

echo "Found Channel ID: $CHANNEL_ID" >&2

# --- 2. Use the extracted Channel ID to fetch subscriptions ---
SUBS_URL="https://www.googleapis.com/youtube/v3/subscriptions?part=snippet&maxResults=100&key=${API_KEY}&channelId=${CHANNEL_ID}" # Using 50 to minimize API calls



echo "Fetching subscriptions for Channel ID: $CHANNEL_ID ..." >&2

SUBS=$(curl -s "$SUBS_URL" | jq -r '.items[].snippet.title')


if [[ -z "$SUBS" ]]; then
  echo "$CHANNEL_NAME's subscriptions are private" >&2
  echo ""
  exit 3 # Exit the script if no ID was found
fi

# --- Extract and print only the channel titles ---
# Fetch the subscriptions, pipe to jq to extract titles
# Use -r for raw output (no quotes), iterate through items array, get snippet.title

if [[ "$MODE" == "adv" ]]; then

  # --- 2. Fetch the subscription list JSON ONCE ---
  SUBS_URL="https://www.googleapis.com/youtube/v3/subscriptions?part=snippet&maxResults=50&key=${API_KEY}&channelId=${CHANNEL_ID}"
  echo "Fetching subscriptions for Channel ID: $CHANNEL_ID ..." >&2
  SUBS_JSON=$(curl -s "$SUBS_URL")

  # --- 3. Check if items exist and get the count ---
  ITEM_COUNT=$(echo "$SUBS_JSON" | jq '.items | length')


  echo "--- Subscription Details (First $ITEM_COUNT channels) ---" >&2
  for (( i=0; i<ITEM_COUNT; i++ )); do
    # Extract data for the current item using jq and the index 'i'
    TITLE=$(echo "$SUBS_JSON" | jq -r ".items[$i].snippet.title // \"N/A\"")
    DESC=$(echo "$SUBS_JSON" | jq -r ".items[$i].snippet.description // \"N/A\"")
    PUB_DATE=$(echo "$SUBS_JSON" | jq -r ".items[$i].snippet.publishedAt // \"N/A\"")

    # Print the extracted data
    echo $TITLE
    echo "  Subscribed On: $PUB_DATE"
    # Prevent description from breaking formatting if it has newlines - using printf
    printf "  Description: %s\n" "$DESC"
    echo ""
    echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
    echo ""
  done
fi


echo ""
echo "$CHANNEL_NAME is subscribed to:"
echo ""
curl -s "$SUBS_URL" | jq -r '.items[].snippet.title'

# Note: This initial call only gets the first 50.
# A full implementation would need to loop using 'nextPageToken' from the JSON response
# until no more pages are available, appending the results each time.
# For simplicity here, we're just showing the first page of results.

echo "" >&2 # Add a newline for cleaner status output separation
echo ""
echo ""
# Note: This will only show subscriptions if the target channel has made them public.
# If no names are printed, their subscriptions are likely private or they have none public.