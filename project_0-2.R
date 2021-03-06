# - Basic instructions and data import
#Import libraries:
library(qvalue)
library(testthat)

#Set up input for Sanjid to use next week.

#Do TDD stuff! Write the damn tests! And make program modular.
#Tests come wherever you are generating an output
#First produce checklists of assertions and outcomes, then produce code to test the validity of outcomes

WD <- getwd()
# cat("Working directory is:", WD)

# For citation:
citeQ <- "John D. Storey with contributions from Andrew J. Bass, Alan Dabney and David Robinson (2015). qvalue: Q-value estimation for false
  discovery rate control. R package version 2.4.2. http://github.com/jdstorey/qvalue"
# cat("This script uses the Q-value package from the open-source project Bioconductor:", "\n", citeQ, "\n")

# myfile <- as.character("Hair.csv")
# read.csv('Hair.csv')->Metab
myfile <- as.character("RawData.csv")
read.csv('RawData.csv')->Metab
read.csv('inj_order_SGA_hair.csv')->InjOrder #load injection order data file with equipment status

MetabInfo<-Metab #dump Metab into MetabInfo
CompoundNames<-MetabInfo[1]
CompoundNames<-t(CompoundNames)
Metab<-Metab[,-c(1)] #subtract compound names
Metab<-t(Metab) #Values from rows into columns, so sample names are on rows
Metab<-as.data.frame(Metab)
Missing<-is.na(Metab) #Allows to check for NA values (reports TRUE/FALSE for each value)
nColumns<-dim(Metab)[2] #no. of columns is set to dimensions of Metab columns
nRows<-dim(Metab)[1]
# - So now data is set up so that Metab[2,4] = [S04, Compound 4 value] etc.

# - Get C or S for each sample so can do just of one group
Type<-substr(rownames(Metab),1,1) #Grab first letter of rownames
Type[Type=='X']<-'Sample' #Define as either C or S for each sample
Type<-factor(Type) #Coerce vector Type to a factor with two levels (C and S)

orderA <- InjOrder$injection.order
maxnRows <- max(nRows)
finalorderSamples <- c(orderA[1:maxnRows])

# - Sort out batches and injection order stuff
MetabInjOrder <- as.numeric(InjOrder$injection.order)
InjOrderNames <- as.character(InjOrder$Name)
InjTime <- InjOrder$Acquired
Inj.df <- data.frame(Names = InjOrderNames, Order = MetabInjOrder, Time = InjOrder$Acquired, Case.control = InjOrder$Case.control)

InjFinal <- Inj.df[ !(is.na(InjOrder$Case.control)), ] #instead of removing stuff that isn't C/S, use an attrib of the data frame

LogMeasurements <- log10(Metab) #Perform log transformation on measurements
LogMeasurements <- as.matrix(LogMeasurements) #Coerce the vector into a matrix for later use

# - Doing logs and stuff
LogMeasurements <- log10(Metab)
LogMeasurements <- as.matrix(LogMeasurements)

InjFinal$Names <- gsub("^C(\\d)$", "C0\\1", InjFinal$Names) #need to turn C1 -> C01 etc. for parity between Metab and InjOrder
InjFinal$Names <- gsub("^S(\\d)$", "S0\\1", InjFinal$Names) #for S1 -> S01 etc.

MetabRowNamesDataFrame <- data.frame(Names = rownames(Metab))
InjectionOrderForMatch <- as.data.frame(InjFinal)

#Rowmatch will only return non-null values if the grep = true. therefore if Lorder has length=83 (Length==nColumns) and is filled with non-null values, test has passed.

RowMatch <- function(rr) {
  ForMatch <- as.character(MetabRowNamesDataFrame$Names[rr])
  if(grep(ForMatch, InjectionOrderForMatch$Names, value = TRUE) == MetabRowNamesDataFrame$Names[rr]) {
    zz <- grep(ForMatch, InjectionOrderForMatch$Names, value = FALSE)
    MatrixToOrder <- c(InjectionOrderForMatch$Names[rr], InjectionOrderForMatch$Order[zz])
    # cat(InjectionOrderForMatch$Names[rr], "\t", InjectionOrderForMatch$Order[zz], "\n")
  }
  sort(MatrixToOrder)
}

nrowsMetabNames <-dim(MetabRowNamesDataFrame)[1]
Lorder <- 0
for (i in 1:nrowsMetabNames) {
  Lorder[i] <- RowMatch(i)
}
Lorder <- as.numeric(Lorder)

# - The below function makes a graph of non-log conc. vs samples
mkSingleGraph <- function(d) { #d = no. of compound you want to plot
  # - Plotting things out
  mod1 <- lm(Metab[,d]~Lorder, subset=Type=='C')
  titleRel <- c(CompoundNames[,d], "R^2 = ", signif(summary(mod1)$r.squared,3) )
  plot(Lorder, Metab[,d], main = titleRel, xlab = "Injection Order", ylab = "Relative Intensity", col=Type)
  # - Making a trendline
  # abline(mod1)
  #Should probably include a legend for Type/Colouring
}

mkSingleGraphNORDER <- function(d) { #d = no. of compound you want to plot
  # - Plotting things out
  mod1 <- lm(Metab[,d]~Lorder, subset=Type=='C')
  titleRel <- c(CompoundNames[,d], "R^2 = ", signif(summary(mod1)$r.squared,3) )
  plot(1:83, Metab[,d], main = titleRel, xlab = "Sample No.", ylab = "Relative Intensity", col=Type)
  # - Making a trendline
  # abline(mod1)
  #Should probably include a legend for Type/Colouring
}

y.lim <- c(-2, 3)

mkSingleGraphLog <- function(b) { #b = no. of compound you want to plot - log scale, and by injection order
  # - Plotting things out, inc. model
  y<-LogMeasurements[Type=='C',b]
  x<-Lorder[Type=='C']
  mod1 <- lm(y~x)
  titleLog <- c(CompoundNames[,b], "R^2 = ", signif(summary(mod1)$r.squared,3) )
  plot(Lorder, LogMeasurements[,b], main = titleLog, xlab = "Injection Order", ylab = "Log Relative Intensity", col=Type)#, ylim = y.lim)
  abline(mod1)
  X <- subset(LogMeasurements[,b], Type == "C")
  Y <- subset(LogMeasurements[,b], Type == "S")
  sig <- t.test(X, Y)
  sig
  devAskNewPage(ask = TRUE)
}

#for the test case for graphs: see if points in table and graph correlate properly

#if you don't want to use numbers!
mkGraphName <- function() {
  nameinput <- readline(prompt = "Enter a compound name: ")
  nameinput <- ifelse(grepl("[^A-Za-z0-9]", nameinput),NA,nameinput) # if the input isn't a text string, including digits, mark as NA
  if (is.na(nameinput)) {
    cat("'", nameinput, "'", "is not a valid text string for matching! Please try again.")
  }
  else
    
  collookup <- grep(nameinput, CompoundNames, ignore.case = TRUE, value = FALSE) #looks up column compound names, returns column number
  # now need to sort out if grep returns more than one value (i.e. search "Alanine", get Phe and Ala)
  alphabeta <- grep(nameinput, CompoundNames, ignore.case = TRUE, value = TRUE) #get the corresponding match names from a repeat grep
  nMatches <- length(collookup) #store "length" (i.e. number) of lookups
  
  if (nMatches == 1) { #if length is equal to 1, there's only one option
    cat("Plot", alphabeta, "as log?", " ")
    readline(prompt = "Y / N: ") -> YorN
    if(grepl("Y", YorN, ignore.case = TRUE) == TRUE) {
    mkSingleGraphLog(collookup)
    }
    if(grepl("N", YorN, ignore.case = TRUE) == TRUE) {
      mkSingleGraph(collookup)
    }
}
  if (nMatches > 1) {  #if more than one match was obtained...
    cat(nMatches, "matches found. Which option do you want to plot?") #print a descriptive message asking for input
    state <- 1 #just an iterator variable for the following loop
    for(i in collookup){ #for as many values as collookup has (i.e. no. of matches returned)
      cat("\n", " ", alphabeta[state], " ", "(",state,")") #print the match name, and number (for user input), each on a new line
      state <- state+1 #increase the iterator so we move through the values
    }
    readline("Enter a positive integer: ") -> SelectiveInput #this is where we ask for input in the form of a +ve integer, corresponding to above matches
    SelectiveInput <- ifelse(grepl("[^0-9]", SelectiveInput),NA,as.integer(SelectiveInput)) #if they don't give us a +ve integer, mark as NA
    while (is.na(SelectiveInput)) { #As long as the input is set as "NA"
      readline("Error. Please enter a positive integer: ") -> SelectiveInput #Throw up an error and ask them to try again
      SelectiveInput <- ifelse(grepl("[^0-9]", SelectiveInput),NA,as.integer(SelectiveInput)) #Please get it right this time, user
    }
    cat("Plot", alphabeta[SelectiveInput], "as log?", " ") #ask for Y/N as to whether the user wants to plot on log scale
    readline(prompt = "Y / N: ") -> YorN #assign the input to a vector for later use
    if(grepl("Y", YorN, ignore.case = TRUE) == TRUE) { #if vector YorN matches "Y/y", then...
      mkSingleGraphLog(collookup[SelectiveInput]) #Make a graph based on the integer provided on log scale
    }
    if(grepl("N", YorN, ignore.case = TRUE) == TRUE) { #Or if it matches "N/n" then plot on standard scale
    mkSingleGraph(collookup[SelectiveInput])
    }
  }
  if(nMatches == 0) { #if no matches found...
    cat("No matches found for string", "'", nameinput, "'") #throw up an error message
  }
}


# - Making linear models

# - Model 2: Before/After "break" (gap in days during experiment)
IsBreak <- 36 # this will be a single value: the injection number of the sample done immediately before the break
               # break was found at Sample C30 (94), So everything <=36 in the list is before the break (= TRUE)
              #maybe make this modular with a readline() command later?
Lorder.m <- as.matrix(Lorder)
RowLorder.m <- row(Lorder.m)
BreakSplit <- Lorder <= IsBreak #The split is defined as a logical vector  
BreakSplitC <- subset(BreakSplit, Type == "C")

#a logical value that will factor Lorder into two levels at the split

LogMeasurementsC <- subset(LogMeasurements, Type == "C") #making subsets of LogMeasurements containing only 
LogMeasurementsS <- subset(LogMeasurements, Type == "S") #cases or controls, for brevity in later functions

Stairstep.df=data.frame(BreakSplitC = rep(0, length(LogMeasurements) ) ) #this creates an "empty" dataframe of the same length of LogMeasurements
Stairstep.df=data.frame(BreakSplitC = BreakSplit) #so that the predict() function has appropriate input

#From here on out, just looking at log(relative intensity) as a scaling normalisation step

mod2 <- lm(LogMeasurementsC ~ BreakSplitC) #init the stairstep model as mod2, using before/after break controls as a divider
summ.mod2 <- summary(mod2) #assign the summary of the model statistics to a vector
predict.mod2 <- predict(mod2, Stairstep.df = Stairstep.df) #create a vector for predictions using the earlier dataframe

R2.Break <- 0 #init a new vector for storing R^2s

AllR2.Break <- function(i) { #where the input is the number of the compound name, and the break R^2
  Reg <- regexpr("r.squared = ", summ.mod2[i]) #the regular expresssions are necessary
  RegStart <- Reg+12                           #as summary()$r.squared seems to run into problems with the break model (mod2)
  RegEnd <- Reg+28
  R2.Break[i] <- substring(grep("[\\d+]", summ.mod2[i], ignore.case = TRUE, value = TRUE), RegStart,RegEnd) #put the digits corresponding to the R^2 into a string
  cat(signif(as.numeric(R2.Break[i]),3), "\n" ) #reduce to
}

R2.Linear <- 0
#Doing the same as above but for linear model R^2s
AllR2.Linear <- function(i) {
  mod1 <- lm(LogMeasurements[,i]~Lorder, subset=Type=='C')
  cat(CompoundNames[,i], "\t", signif(summary(mod1)$r.squared,3), "\t" )
}

GetAllR2 <- function() { #A function to output the R^2s for both models comparatively in a .tdt (tab-delimited) compatible format
  cat("Compound", "\t", "LINEAR R^2", "\t", "BREAK R^2", "\n")
  for (i in seq_along(CompoundNames)) {
    AllR2.Linear(i)
    AllR2.Break(i)
  }
}

DoCorrection.Linear <- function(i) { #this function performs corrections to the data based on the linear model (centering, scaling, subtraction of residuals)
  y <- LogMeasurements[Type=='C',i]  #placing the measurements for a single compound into a vector
  x <- Lorder[Type=='C'] #putting the injection order into another vector for model use
  mod1 <- lm(y ~ x) #recreating mod1 for JUST the compound being tested
  TotalDataForPredict=data.frame(x=Lorder) #prediction data frame init
  predict.mod1 <- predict(mod1, newdata=TotalDataForPredict) #outputting predict() into a vector
  finalvalues <- LogMeasurements[,i]  - predict.mod1 #subtracting the residuls (above output) to correct data based on subtracting residuals
  sig <- t.test(finalvalues~Type) #perform parametric t-test with welch's correction on the data to test for case/control differences in means
  title <- c(CompoundNames[,i], "Linear Model", "t.test p =", signif(sig$p.value,3)) #create a title vector inc. compound name and 
  plot(Lorder, finalvalues, main = title, xlab = "Injection Order", ylab = "Log Relative Intensity", col=Type, ylim = y.lim) #
  devAskNewPage(ask = TRUE) #ask for the user to press ENTER before producing the next graph
}

DoCorrection.Break <- function(i) { #as above, but for the stairstep model
  y <- LogMeasurements[Type=='C',i]
  x <- BreakSplit[Type=='C']
  mod2 <- lm(y ~ x)
  TotalDataForPredict = data.frame(x = BreakSplit)
  predict.mod2 <- predict(mod2, newdata = TotalDataForPredict)
  finalvalues2 <- LogMeasurements[,i]-predict.mod2
  sig <- t.test(finalvalues2~Type)
  title <- c(CompoundNames[,i], "Step Model", "t.test p =", signif(sig$p.value,3))
  plot(Lorder, finalvalues2, main = title, xlab = "Injection Order", ylab = "Log Relative Intensity", col=Type, ylim = y.lim)
  devAskNewPage(ask = TRUE)
}

   # The below code is deprecated and will eventually be removed
# LinearCorrectionGraph <- function(i) {
#   LinearCorrections <- DoCorrection.Linear(i)
#   plot(Lorder, LinearCorrections, main = CompoundNames[,i], xlab = "Injection Order", ylab = "Log Relative Intensity", col=Type)
#   C <- subset(LinearCorrections, Type == "C")
#   S <- matrix(subset(LinearCorrections, Type == "S"))
#   sig <- t.test(C, S, alternative = "t", mu = 0, paired = FALSE, var.equal = TRUE)
#   sig2 <- kruskal.test(LinearCorrections, Type)
#   cat("Linear model:", "\n", "T-test p-value:", sig$p.value, "\n", "Kruskal-Wallis p-value:", sig2$p.value, "\n", "\n") #prints both models' stats
# }
# 
# BreakCorrectionGraph <- function(i) {
#   BreakCorrections <- DoCorrection.Break(i)
#   plot(Lorder, BreakCorrections, main = CompoundNames[,i], xlab = "Injection Order", ylab = "Relative Intensity", col=Type) #plot a graph
#   C <- subset(BreakCorrections, Type == "C")
#   S <- subset(BreakCorrections, Type == "S")
#   sig <- t.test(C, S, alternative = "t", mu = 0, paired = FALSE, var.equal = TRUE) #Performs t-test on normalised data from break model
#   sig2 <- kruskal.test(BreakCorrections, Type) #Performs a Kruskal-Wallis non-parametric significance test
#   cat("Break model:", "\n", "T-test p-value:", sig$p.value, "\n", "T-test q-value:", "\n", "Kruskal-Wallis p-value:", sig2$statistic, "\n", "\n") 
# }

pval.mod1 <- 0 #initing vectors for use in later function
pval.mod2 <- 0
pval.mod3 <- 0
DOC.mod1 <- 0
DOC.mod2 <- 0

#qval stuff, also making model3
#

for(i in 1:nColumns) { #this way the results for all compounds, for each model, will be stored in globally-accessible matrices for later use
  mod1 <- lm(LogMeasurements[,i] ~ Lorder, subset = Type == 'C') #recreating model 1 in this fashion (for all compounds)
  mod2 <- lm(LogMeasurements[,i] ~ BreakSplit, subset = Type == 'C') #same for model 2 (stairstep)
  mod3 <- lm(LogMeasurements[,i] ~ Type + Lorder) #and for model 3 "confounder" - a linear regresssion as in mod1, but with case/control split as primary variable
  pval.mod1[i] <- summary(mod1)$coef[2,4] #produce pvalues for each model
  pval.mod2[i] <- summary(mod2)$coef[2,4]
  pval.mod3[i] <- summary(mod3)$coef[2,4]
  DOC.mod1[i] <- summary(mod1)$coef[1,3] #and use one of the column summaries (t sign) to get the direction of change (between cases/controls) of the compound for each model
  DOC.mod2[i] <- summary(mod2)$coef[1,3]
}

qvals.mod1 <- signif(qvalue(pval.mod1, lambda=0.01)$qval, 3) #computes Benjamini-Hochburg qvalue for mod1, limits to 3 significant figures for readability
qvals.mod2 <- signif(qvalue(pval.mod2, lambda=0.01)$qval, 3) #"" "" for mod 2
qvals.mod3 <- signif(qvalue(pval.mod3, lambda=0.01)$qval, 3) #"" ""for mod 3


ShowAndTell <- function(i) { #this function produces the full set of graphs for a given compound, where i is the rownumber of that compound in Metab[]
  mkSingleGraphLog(i)
  DoCorrection.Linear(i)
  DoCorrection.Break(i)
  cat(CompoundNames[,i], "\n", "Type covar. p-value:", pval.mod3[i], "\n", "Q-values for each model:", "\n", "Linear:", qvals.mod1[i], "\n", "Step:", qvals.mod2[i], "\n", "Linear covar. with Type:", qvals.mod3[i], "\n", "DOC1:", DOC.mod1[i], "\n", "DOC2:", DOC.mod2[i], "\n")
} #and gives descriptive output as required

source("TESTING.R") #this runs all tests for the script, using the testthat package, in a separate file