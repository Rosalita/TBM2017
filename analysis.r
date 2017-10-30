# Twitter Scraping and sentiment analysis
# The twitteR package for R allows you to scrapte tweets from Twitter's API
# The ROAuth package provides an interface allowing users to authenticate via OAuth
# The httr package provides useful tools for working with HTTP, GET(), POST() etc.
# The stringr package provides useful string operations
# The readr package reads a file into a string
# The tm package is a framework for text mining packages within R
# The wordcloud package lets you make pretty word clouds

#install.packages("twitteR")
#install.packages("openssl")
#install.packages("RCurl")
#install.packages("curl")
#install.packages("ROAuth", dependencies = TRUE)
#install.packages("bitops")
#install.packages("httr")
#install.packages("stringr")
#install.packages("readr")
#install.packages("tm", dependencies = TRUE)
#install.packages("wordcloud", dependencies = TRUE)
#install.packages("ggplot2")
#install.packages("colorspace")

library(twitteR)
library(ROAuth)
library(httr)
library(stringr)
library(readr)
library(tm)
library(wordcloud)
library(ggplot2)
library(scales)


# Set working directory to project root
setwd("C:/Git/TBM2017")
#getwd()


# Make sure Twitter account has a phone number attached.
# Go to Twitter apps page (https://apps.twitter.com/) and create a new app
# Once app is created, this will give Keys and Access tokens

# For security, to keep secrets secret they are stored in environment variables! 
# API Secret and Access Token Secret should never be human readable,

#TWITAPISECRET <- Sys.getenv("TWITAPISECRET") 
#TWITTOKENSECRET <- Sys.getenv("TWITTOKENSECRET")

# Set API Keys 
#api_key <- "aVXP1fw3fyxFFYfSDsAKje3vy"
#api_secret <- TWITAPISECRET
#access_token <- "69366834-DdbmXBAxgxybC27MSBK3gaojj26Qcdr5Mi1rSzGpd"
#access_token_secret <- TWITTOKENSECRET 
#setup_twitter_oauth(api_key, api_secret, access_token, access_token_secret)
# Collect tweets with hashtag #testbash
#tweets <- searchTwitter("#testbash", n=5000)

# this had to be done as twitter api only stores a sample of tweets for a 
# around 10 days so this information needs to be collected and saved
# converted tweets collected to a data frame.
#tweetdf <- twListToDF(tweets)

# saved the dataframe object as a .Rda file
# 2700 tweets saved
# saveRDS(tweetdf,file="testbashtweets.Rda")

# load dataframe of testbash tweets which intend to perform analysis on
testbashtweets <- readRDS("testbashtweets.Rda")

