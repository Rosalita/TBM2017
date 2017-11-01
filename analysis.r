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
#install.packages("SnowballC")

library(twitteR)
library(ROAuth)
library(httr)
library(stringr)
library(readr)
library(tm)
library(wordcloud)
library(ggplot2)
library(scales)
library(SnowballC)


# Set working directory to project root

#setwd("C:/Git/TBM2017")

setwd("C:/Dev/Git/TBM2017")

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


#clean up the tweets because we want to perform analysis on test bash Manchester

#create an index of tweets about testbash events in Philadelphia, Brighton and Netherlands
#othersindex <- grep("Philadelphia|Philly|Philad|Brighton|Netherlands", testbashtweets[,1])
othersindex <- grep("Netherlands", testbashtweets[,1])



#407 is false positive picked up by grep that mentions both testbash manchester and netherlands
#so make sure tweet 407 is not the index of tweets to be removed
#othersindex <- othersindex[which(othersindex!=407)] 

#apply index to tweets to discard tweets about non-manchester events
testbashtweets  <- testbashtweets[-othersindex,]

#fix row names after removing some rows
row.names(testbashtweets) <- 1:nrow(testbashtweets)

# extract tweet text
tweet_text <- testbashtweets$text


#library(plyr)
# laply splits a list, applies function, then returns results in an array
#tweet_text = laply(latest_tweets, function(x) x$getText())
tweet_text <- iconv(tweet_text, to='UTF-8') # convert all tweets to UTF8 to make emojis play nice


# As a starting point, use the Hu and Liu Opinion Lexicon 
# from http://www.cs.uic.edu/~liub/FBS/opinion-lexicon-English.rar
# This is two lists, one of positive words and one of negative words
# This lexicon has been adjusted to be sensitive to the domain it is analysising
# Words specific to the domain of software development have been added e.g.'wagile'
# a negative term used to describe agile development which has reverted back to waterfall
# also corrections have been made based on context, e.g. the word 'buzzing' has been 
# reclassified from negative to positive.
# UK spellings like 'honour' as oppose to US 'honor' have been included
# Also removed from word lists all positive and negative words present in titles of each speakers talk  
# did this to try mitigate bias as words in talk titles will be mentioned more frequently
# words removed: critical, social, positivity, frown, skill, harmed, problems, deadly, sins, sin, awesomeness

# Import the good words and get them into vectors
good <- read_file("positive-words.txt", locale = default_locale())
good = gsub('[[:cntrl:]]', ' ',good)  # replace control characters, like \n or \r with a space 
good.list = str_split(good, '\\s+')   # split into a list of words
good_text = unlist(good.list)         # make sure words is a vector, not a list
good_text = good_text[1:(length(good_text) -1)] # the last item appears to be "", so just trim it off


bad <- read_file("negative-words.txt", locale = default_locale())
bad = gsub('[[:cntrl:]]', ' ',bad)  # replace control characters, like \n or \r with a space 
bad.list = str_split(bad, '\\s+')   # split into a list of words
bad_text = unlist(bad.list)         # make sure words is a vector, not a list
bad_text = bad_text[1:(length(bad_text) -1)] # the last item appears to be "", so just trim it off

# initialise some global variables
positivity <- NULL
negativity <- NULL

# Now score the text of each tweet based on count of positive and negative words used.

score.sentiment = function(sentences, good_text, bad_text, .progress='none')
{
  require(plyr)
  require(stringr)
  # we got a vector of sentences. plyr will handle a list
  # or a vector as an "l" for us
  # we want a simple array of scores back, so we use
  # "l" + "a" + "ply" = "laply":
  scores = laply(sentences, function(sentence, good_text, bad_text) {
    
    # clean up each sentence with R's regex-driven global substitute, gsub():
    sentence = gsub('[[:punct:]]', '', sentence)  # strips out punctuation
    sentence = gsub('[[:cntrl:]]', '', sentence)  # strips out control characters, like \n or \r 
    sentence = gsub('\\d+', '', sentence)         # strips out numbers
    sentence <- iconv(sentence, to='UTF-8')       # convert to UTF8
    sentence = tolower(sentence)                  # converts all text to lower case     
    word.list = str_split(sentence, '\\s+')       # split into a list of words
    words = unlist(word.list)                     # make sure words is a vector, not a list
    
    # compare our words to the dictionaries of positive & negative terms
    pos.matches = match(words, good_text)
    neg.matches = match(words, bad_text)
    
    # match() returns the position of the matched term or NA
    # convert matches to TRUE/FALSE instead
    pos.matches = !is.na(pos.matches)
    neg.matches = !is.na(neg.matches)
    
    # TRUE/FALSE is treated as 1/0 by sum(), so add up the score
    score = sum(pos.matches) - sum(neg.matches)
    
    #if any positive matches
    if (any(pos.matches)){
      pos.matches = match(words, good_text)
      pos.words = good_text[pos.matches] # apply index of pos matches to get pos words
      pos.words = pos.words[!is.na(pos.words)] # remove any NA values
      # append positive words to global positivity variable
      positivity <<- append(positivity, pos.words)
    }
    
    # identify the words which matched positively or negatively
    # maybe use <<- to set pos.words and neg.words as global variables?
    if (any(neg.matches)){
      neg.matches = match(words, bad_text)
      neg.words = bad_text[neg.matches] # apply index of neg matches to get neg words
      neg.words = neg.words[!is.na(neg.words)] # remove any NA values 
      #append negative words to global negativity variable
      negativity <<- append(negativity, neg.words)
    }
    
    return(score)
  }, good_text, bad_text, .progress=.progress )
  
  scores.df = data.frame(score=scores, text=sentences)
  return(scores.df)
}

# Call the score sentiment function and return a data frame
feelings <- score.sentiment(tweet_text, good_text, bad_text, .progress='text')

sentiment_score <- feelings$score

#bind the sentiment scores onto the tweet dataframe
testbashtweets <- cbind(testbashtweets,sentiment_score)

# add * to swear words so word clouds are less offensive
findex <- which(negativity =="fuck")
negativity[findex] <- "f*ck"
findex <- which(negativity =="fucking")
negativity[findex] <- "f*cking"
findex <- which(negativity =="shit")
negativity[findex] <- "sh*t"

#tally up all the positive and negative words in a table.
ptable <- table(positivity)
ntable <- table(negativity)

# Word clouds

library(tm)
library(wordcloud)

# make a corpus for positive and negative words
pcorp = Corpus(VectorSource(positivity))
ncorp = Corpus(VectorSource(negativity))

#pcorp <- tm_map(pcorp, PlainTextDocument)
#ncorp <- tm_map(ncorp, PlainTextDocument)

# Basic Wordcloud
# wordcloud(pcorp, max.words = 100, random.order = FALSE)

# Start a new plot frame
plot.new()

# Set the display a 2 by 2 grid
par(mfrow=c(1,2))

# Outer Margins
par(oma=c(0.5,0.1,0.5,0.1))
# Margins, bottom, left, top, right (default is  c(5,4,4,2))
par(mar=c(0.1,1,0.1,1))

# par(mar=c(9.3,4.1,4.1,2.1))
# par(mfrow=c(2,2))
# par(cex.axis=1.3)
# par(cex.main=1.3)




# Positive Wordcloud
wordcloud(pcorp, 
          scale=c(2,0.7), 
          max.words=300,
          min.freq=-1,
          random.order=FALSE, 
          rot.per=0.2, 
          use.r.layout=FALSE, 
          # Nice custom blue to green sequential colours
          colors = c(#"#ACF8A5",
            #"#8DE99B",
            #"#77DB9D", 
            "#63CDA4", 
            "#50BFAE",
            "#3FA7B1", 
            "#307EA2", 
            "#235594", 
            "#172F86",
            "#100E78",
            "#200569"))

text(x=-0.03, y=0.5, "Positive Words", srt=90)

#mtext("This is my margin text", side=2, line =1)
# colors=brewer.pal(5, "BuGn"))

# Negative Wordcloud
wordcloud(ncorp, 
          scale=c(2,0.7), 
          max.words=300, 
          min.freq=-1,
          random.order=FALSE, 
          rot.per=0.2, 
          use.r.layout=FALSE, 
          # Nice custom yellow to red colours
          colors = c(#"#FFDE6A",
            #"#F4C55C",
            "#E9AC4F", 
            "#DF9343", 
            "#D47A37",
            "#CA612D", 
            "#BF4A23", 
            "#B4331A", 
            "#AA1D11",
            "#9F0A0C"))
#"#950312"))

# colors=brewer.pal(5, "Reds"))

text(x=1.03, y=0.5, "Negative Words", srt=270)
#mtext("This is my margin text", side=4, line =0, adj=1)



#separate out the date from the tweet creation time stamp
justdate <- as.Date(testbashtweets$created)
#justtime <- format(testbashtweets$created,"%H:%M:%S")

#bind date onto the dataframe
testbashtweets <- cbind(testbashtweets, justdate)

# subset the data to identify tweets created on 27-10-17, the day of the conference. 
index <- which(testbashtweets[,18] == "2017-10-27")
confdaytweets <- testbashtweets[index,]

#correct row names for confdaytweets dataframe
row.names(confdaytweets) <- 1:nrow(confdaytweets)

#clean up a few rogue tweets from the night before conference day
previousevening <- 1676
confdaytweets <- confdaytweets[-previousevening,]

#correct row names for confdaytweets dataframe
row.names(confdaytweets) <- 1:nrow(confdaytweets)

# It appears created time stamps on all tweets are 1 hour behind, possibly due to daylight savings time
# So add an hour on, posixct is time from unix epoch so an hour is + 60*60
 confdaytweets$created <- confdaytweets$created + (60*60)



#bind a column on to conference day tweets to hold key times to divide the plot
keytimes <- NA
confdaytweets <- cbind(confdaytweets, keytimes)

#indicate first line is at 08:00 am
confdaytweets[1,19] = "2016-10-21 08:00:00 GMT" # start time
confdaytweets[2,19] = "2016-10-21 09:00:00 GMT" # end of lean coffee
confdaytweets[3,19] = "2016-10-21 09:10:00 GMT" # Anne-Marie Charrett start
confdaytweets[4,19] = "2016-10-21 10:00:00 GMT" # Goran Kero start
confdaytweets[5,19] = "2016-10-21 10:30:00 GMT" # break start
confdaytweets[6,19] = "2016-10-21 11:00:00 GMT" # Gem Hill start
confdaytweets[7,19] = "2016-10-21 11:30:00 GMT" # Bas Dijkstra start
confdaytweets[8,19] = "2016-10-21 12:00:00 GMT" # James Sheasby Thomas start
confdaytweets[9,19] = "2016-10-21 12:30:00 GMT" # lunch start
confdaytweets[10,19] = "2016-10-21 13:30:00 GMT" # Vera Gehlen-Baum start
confdaytweets[11,19] = "2016-10-21 14:00:00 GMT" # Simon Dobson start
confdaytweets[12,19] = "2016-10-21 14:30:00 GMT" # break start
confdaytweets[13,19] = "2016-10-21 14:40:00 GMT" # Martin Hynie start
confdaytweets[14,19] = "2016-10-21 15:20:00 GMT" # break start
confdaytweets[15,19] = "2016-10-21 15:50:00 GMT" # Claire Reckless start
confdaytweets[16,19] = "2016-10-21 16:20:00 GMT" # Michael Bolton start
confdaytweets[17,19] = "2016-10-21 17:15:00 GMT" # 99 second talk start
confdaytweets[18,19] = "2016-10-21 17:45:00 GMT" # end time
# add time stamps for mid points so some labels can be plotted in the middle of rects
confdaytweets[19,19] = "2016-10-21 08:30:00 GMT" # mid lean coffee
confdaytweets[20,19] = "2016-10-21 09:35:00 GMT" # mid Anne-Marie
confdaytweets[21,19] = "2016-10-21 10:15:00 GMT" # mid Goran
confdaytweets[22,19] = "2016-10-21 11:15:00 GMT" # mid Gem
confdaytweets[23,19] = "2016-10-21 11:45:00 GMT" # mid Bas
confdaytweets[24,19] = "2016-10-21 12:15:00 GMT" # mid James
confdaytweets[25,19] = "2016-10-21 13:45:00 GMT" # mid Vera
confdaytweets[26,19] = "2016-10-21 14:15:00 GMT" # mid Simon
confdaytweets[27,19] = "2016-10-21 15:00:30 GMT" # mid Martin
confdaytweets[28,19] = "2016-10-21 16:05:00 GMT" # mid Claire
confdaytweets[29,19] = "2016-10-21 16:50:00 GMT" # mid Michael
confdaytweets[30,19] = "2016-10-21 17:30:00 GMT" # mid 99 Second Talks
# add time stamps for xlim on plots
confdaytweets[31,19] = "2016-10-21 05:30:00 GMT"
confdaytweets[32,19] = "2016-10-22 01:30:00 GMT"  

# convert location of lines to dates to POSIXct
confdaytweets$keytimes <- as.POSIXct(confdaytweets$keytimes, tz="GMT")

str(confdaytweets$keytimes)

#p <- ggplot(confdaytweets, aes(x = created, y = sentiment_score))



# plot tweets on 21-10-16, the day of the conference by time and sentiment
plot <- ggplot(confdaytweets, aes(x = created, y = sentiment_score))+
  geom_jitter(alpha = 0.4)+ 
  ggtitle("Tweets by Time and Positivity for #testbash Manchester on 27-10-17")+
  labs(x="Time", y="Positivity Index")+
  
  scale_x_datetime(date_breaks = "2 hour", date_labels = "%H:%M")+ #use scale_*_datetime for POSIXct variables
  scale_y_continuous(breaks = c(-4,-3,-2,-1,0,1,2,3,4,5,6))
  

plot

plot + geom_smooth(method ="loess", span=0.05, colour="cyan" )


#most positive tweet  
index <- which(confdaytweets$sentiment_score == 4)
positive_tweets <- confdaytweets[index,]


# Manually remove the RTs as they are duplication of the positive tweet
Most_positive  <-   positive_tweets$text[4]

# link to actual tweet 
# https://twitter.com/FriendlyTester/status/923999256331079681



#most negative tweets    
index <- which(confdaytweets$sentiment_score == -5)
neg_tweets <- confdaytweets[index,]
Most_negative <- c(neg_tweets$text[1])

# link to actual tweet
# https://twitter.com/TheTestDoctor/status/923854442969083905


# Top 5 most Favourited tweets
index <- which(confdaytweets$favoriteCount > 27)
top5 <- confdaytweets[index,]

# #1 - 49 favourites
# https://twitter.com/TestPappy/status/923958088792756224

# #2 - 47 favourites
# https://twitter.com/FriendlyTester/status/923999256331079681

# #3 - 38 favourites
# https://twitter.com/marianneduijst/status/923938022093217792

# #4 - 30 favourites
# https://twitter.com/Tweet_Cassandra/status/923812972841127936

# #5 - 27 favourites
# https://twitter.com/RightSaidJames/status/923878721513287680



# try extract platform data for conference day tweets
# Start by binding a column named 'platform' containing NA onto dataframe which will be used to hold this data
platform <- NA
confdaytweets <- cbind(confdaytweets, platform)


#Tweet Lanes is an android apps so include it in android sources
index <- grep("Twitter for Android|TweetCaster for Android|Echofon  Android|Tweet Lanes", confdaytweets$statusSource)
confdaytweets$platform[index] <- "Android"


index <- grep("Twitter for iPhone", confdaytweets$statusSource)
confdaytweets$platform[index] <- "iPhone"

index <- grep("Tweetbot for i??S", confdaytweets$statusSource)
confdaytweets$platform[index] <- "ios"

index <- grep("Twitter for iPad", confdaytweets$statusSource)
confdaytweets$platform[index] <- "iPad"

index <- grep("Twitter for Mac", confdaytweets$statusSource)
confdaytweets$platform[index] <- "Mac"

index <- grep("Mobile Web", confdaytweets$statusSource)
confdaytweets$platform[index] <- "Mobile Web"

index <- grep("Twitter Web Client", confdaytweets$statusSource)
confdaytweets$platform[index] <- "Web Client"

index <- grep("Twitter for Windows", confdaytweets$statusSource)
confdaytweets$platform[index] <- "Windows"

# Any values still set to NA change their platform to 'Unknown' 
index <- which(is.na(confdaytweets$platform))
confdaytweets$platform[index] <- "Unknown"



# Tweet Frequency polygon

plot2 <- ggplot(confdaytweets, aes(x =confdaytweets$created)) +
  ggtitle("Tweet Frequency by Platform for #testbash Manchester")+
  scale_x_datetime(date_breaks = "2 hour", date_labels = "%H:%M")+
  
  scale_y_continuous(breaks = seq(0,140, by=10))+
  labs(x="Time", y="Tweet Count", colour ="Tweets by platform")+
  geom_freqpoly(binwidth = 900, aes(x=confdaytweets$created, colour="All Platforms"))+
  scale_color_manual(values=c("#000000", "#009939", "#3369e8", "#d50f25",
                              "#eeb211", "#00FFFF","#ff00ff", "#ffff00", "#00ff00"))
  
  
plot2 


# as well as total show quantity of tweets for each platform
plot2 + geom_freqpoly(binwidth = 900, aes(x =confdaytweets$created, colour=platform))








