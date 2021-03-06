#' Generate a topic model with K topics using the implementation of Latent Dirichlet allocation (LDA) in the lda package
#' 
#' @description Generates a topic model with K topics using Latent Dirichlet allocation (LDA, with the lda package) For use with JSTOR's Data for Research datasets (http://dfr.jstor.org/).
#' @param x object returned by the function JSTOR_unpack.
#' @param corpus the object returned by the function JSTOR_corpusofnouns. A corpus containing the documents.
#' @param K the number of topics that the model should contain
#' @param alpha The scalar value of the Dirichlet hyperparameter for topic proportions. Higher values lead to more uniform distributions of topics over documents. Default is 50/K
#' @return Returns a data frame with documents as rows, topics as columns and posterior probabilities as cell values.
#' @examples 
#' ## lda1 <- JSTOR_lda(x = unpacked, corpus = corpus, K = 150) 



JSTOR_lda <- function(x, corpus, K, alpha = 50/K){ 
  
  # prepare bibliodata
  bibliodata <- x$bibliodata
  
  # stop if number of topics is less than 2
  if (as.integer(K) != K || as.integer(K) < 2) 
    stop("\nK needs to be an integer of at least 2")
  
library(tm) # needed to convert corpus to dtm
library(lda)
library(topicmodels) # needed for dtm2ldaformat function
message("converting corpus to document term matrix and then to doclines format...")
dtm <- DocumentTermMatrix(corpus)
message("done")
ldafmt <- dtm2ldaformat(dtm)
wc <- word.counts(ldafmt$documents) #get word counts
# generate topic model
message("generating topic model...")
result <- lda.collapsed.gibbs.sampler(ldafmt$documents, 
                                          K,    # number of topics
                                          ldafmt$vocab, 
                                          100,  # number of iterations
                                          alpha, # alpha, after Griffiths & Steyvers 2004
                                          0.1,  # eta
                                          burnin = 100,
                                          compute.log.likelihood = FALSE
                                          ) # uses a collapsed Gibbs sampler to ﬁt a latent Dirichlet allocation (LDA) model, consider 0.01 for alpha http://www.bytemining.com/2011/08/sigkdd-2011-conference-day-1-graph-mining-and-david-bleitopic-models/

# find top five words per topic to label topics
top.words <- top.topic.words(result$topics, 5, by.score=TRUE) # assign top.words, following the demo(lda)

# make data frame of topics (columns), documents (rows) and probabilities (cells)
topic.proportions <- t(result$document_sums) / colSums(result$document_sums) # assign topic.proportions
topic.proportions[is.na(topic.proportions)] <-  1 / K # etc. from demo(lda)
colnames(topic.proportions) <- apply(top.words, 2, paste, collapse=" ") # assign col names...
topic.proportions <- data.frame(topic.proportions)
# add cols of article ID and year of publication from bibliodata
topic.proportions$ID <- x$bibliodata$x # DOI id of article
topic.proportions$year <- as.numeric(as.character(x$bibliodata$year)) # year of article publication
  
message("done")
return(list("topic.proportions" = topic.proportions, "model" = result))
}












