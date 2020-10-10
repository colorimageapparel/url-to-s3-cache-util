# HTTP Content cacher/consolidator

## What I do

I will sync all files found in environment variables starting with SYNC_FILES

e.g. if `SYNC_FILES_1="xyz.json::https://www.example.com/x.json"`
then I will grab `https://www.example.com/x.json` and save it to the bucket as `xyz.json`
I'll repeat this for all found environment variables of this form.

## Why you might want it

Suppose you are paying for a service that gives you a small number of downloads of some data per month, but you may have dozens of separate nodes that each want to grab updated data hourly. If they all ping the paid service, you will have to pay a bunch more money.
You can run a cronjob of this utility to periodically fetch from the service and mirror the data to your own bucket so that your many web nodes can fetch from it at will without incurring a per-node cost.
