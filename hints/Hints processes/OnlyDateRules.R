

basicTheme = theme(axis.text=element_text(size=13),axis.title.x = element_text(size=20),axis.title.y = element_text(size=20),title = element_text(size=25),legend.text = element_text(size=14)  )
folder = "C:/Users/reedm/UK Parliament/THOMAS, Liz - DAs/Hints/" 
publicFolder = "C:/Users/reedm/UK Parliament/Data & Search - Data and Search (Public)/Search/Result text/"

rules = read.csv(paste0(folder, "bigRulesList.csv"), stringsAsFactors = F)
searchesAndFirstPage <- read.csv(paste0(publicFolder,"termsAndResults.csv"), stringsAsFactors = F)
searchesAndFirstPage$X = NULL


allMatches = read.csv(paste0(folder, "AllHintsMatchedCLeaner.csv") , stringsAsFactors = F)
dateMatches = subset(allMatches, regex %in% rules[grepl("\\{",rules$ruleName),]$rule )
dateRules=rules[grepl("\\{",rules$ruleName),]
dateMatches = subset(dateMatches,!( regex %in% dateRules$rule[c(1,8,9,10,11,12,32,53,54,56,57,59,61,62,63,64,65)]  ))
dateRules = subset(dateRules,!( rule %in% dateRules$rule[c(1,8,9,10,11,12,32,53,54,56,57,59,61,62,63,64,65)]  ))

# not date format = 
# 1,8,9,10,11,12,32,53,54,56,57,59,61,62,63,64,65

maxCover = length(unique(allMatches$uri))/length(unique(searchesAndFirstPage$uri))


uniqueMatches = unique(dateMatches[,c("uri","regex","ruleName")])


# the loop below needs a set of rules, consisting of regular expressions and desriptions (here called 'rules'),
# and a data frame with all the possible matches between a set of uri's and the regular expressions (here this is uniqueMatches)


hold = data.frame(uri = unique(uniqueMatches$uri))

uniqueUri = hold # uniqueUri counts how many hints have been assigned to each uri
coverage = 0
maximumCover = 10 # this is the limit which is imposed on uri's as to how many hints they can have.
thisOne = NULL
uniqueUri$coverage = 0
keeps = data.frame(Var1 = character(),Freq=numeric(),ruleName=character(), cumulative=numeric())

while (coverage < maxCover-0)
{
  matchesbanned = subset(allMatches, uri %in% subset(uniqueUri, coverage >= maximumCover)$uri)
  
  x2=as.data.frame(table(subset(uniqueMatches, !(regex %in% matchesbanned$regex) & 
                                  !(regex %in% thisOne$regex) & !(uri %in% thisOne$uri) )$regex)) # get occurence frequency of each rule, where 
  # using the rule wouldn't lead to a link exceeding the maximumCover and has not already been used.
  
  thisRule = x2[x2$Freq == max(x2$Freq),][1,]
  thisRule=  merge(thisRule,rules, by.x="Var1",by.y="rule")[1,]
  
  if (!grepl("^\\\\\\.\\w+\\??\\$",thisRule$Var1))
    uniqueUri[uniqueUri$uri %in% subset(uniqueMatches, regex== as.character(thisRule$Var1) )$uri,]$coverage= 
    uniqueUri[uniqueUri$uri %in% subset(uniqueMatches, regex== thisRule$Var1 )$uri,]$coverage + 1
  if (!exists("thisOne"))
    thisOne = subset(uniqueMatches, regex == thisRule$Var1 )
  else
    thisOne = rbind(thisOne, subset(uniqueMatches, regex == thisRule$Var1 ))
  coverage = length(unique(thisOne$uri)) / length(unique(searchesAndFirstPage$uri))
  print(paste(coverage, "-",thisRule$Var1[1], thisRule$ruleName[1]  ))
  thisRule$cumulative = coverage
  keeps=rbind(keeps, thisRule)
}


row.names(keeps) = NULL
keeps$name= paste(row.names(keeps),keeps$ruleName)
write.csv(keeps,paste0(folder,"OptimalCover.csv"),row.names=F)

library(ggplot2)
png(paste0(folder,"DateCover.png"),width=1980,height=1020)
ggplot(keeps, aes(x=reorder(name, cumulative), y=cumulative))+geom_point()+ggtitle("Cover by Date hints")+
  theme(axis.text.x= element_text(angle =20,hjust=1  ))+basicTheme+
  geom_text(aes(label =paste0(round(cumulative*100),"%") ), vjust=-1)+ ylab("cumulative url cover")+xlab("hint description")+
  scale_y_continuous(labels = function(x)paste0(x*100,"%"), limits = c(0,1) )
dev.off()

totalMatches = as.data.frame(table(uniqueMatches$regex))
totalMatches = rbind(totalMatches, data.frame(Var1 = subset(dateRules, !(rule %in% totalMatches$Var1))$rule, Freq = 0))
totalMatches = merge(totalMatches, dateRules, by.x="Var1", by.y="rule")
totalMatches = totalMatches[order(-totalMatches$Freq),]
write.csv(totalMatches, paste0(folder, "DateMatches.csv"),row.names=F)






