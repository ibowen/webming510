rm(list = ls());
setwd("C:/MIS510/Labs/Independent/2015Med2000_flatfiles")

medicareData <- read.csv("vwPlanDrugsCostSharing.csv", na.strings = c('NULL', 'NA'))
medicareData <- subset(medicareData,  medicareData$copay_amt_inn_prefrd != "Information Not Available")
#medicareData <- subset(medicareData, medicareData1$copay_amt_inn_prefrd != "")
medicareData <- subset(medicareData, medicareData$copay_amt_mail_ordr_prefrd != "Information Not Available")
#medicareData <- subset(medicareData, medicareData3$copay_amt_mail_ordr_prefrd != "")


mD <- read.csv("vwPlanDrugTierCost.csv")
attach(mD)
mD <- subset(mD, mD$Language == "English")
mail <- grep("Retail", mD$tier_type_desc, value=TRUE)
mail
mD <- subset(mD, mD$tier_type_desc == mail)
mD <- subset(mD, mD$contract_id == "H0022")
#mD <- subset(mD, mD$cost_share_pref != "Information Not Available")
#mD <- subset(mD, mD$cost_share_pref != "")
#mD <- subset(mD, mD$cost_share_gen != "Information Not Available")
#mD <- subset(mD, select = c("contract_id", "plan_id"))
names(medicareData)
install.packages("plyr")
library("plyr")
medicareData <- subset(medicareData, select = c("contract_id", "plan_id","plan_cvrg_typ_id","mnthly_prm", "ann_ddctbl", "copay_amt_inn_prefrd", "coins_amt_inn_prefrd", "copay_amt_mail_ordr_prefrd",
                                                  "coins_amt_mail_ordr_prefrd"))


#mD4 <- mD3[order(mD3$contract_id),]
detach(mD)

#ll <- merge(mD3, medicareData4)

ll <- rbind.fill(mD, medicareData)
llFinal <- subset(ll, !is.na(ll$plan_cvrg_typ_id))


setwd("../2015StarRatings_flatfiles/")

rating <- read.csv("vwStarRating_Measures.csv")
rating <- subset(rating, rating$Language == "English")
rating <- subset(rating, rating$Star_Rating != "Not enough data available" )
rating <- subset(rating, rating$Star_Rating != "No data available")
rating <- subset(rating, rating$Star_Rating != "Plan not required to report measure")
rating <- subset(rating, rating$Star_Rating != "Benefit not offered by plan")
rating <- subset(rating, rating$Star_Rating != "Plan too new to be measured")
rating <- subset(rating, rating$Star_Rating != "Plan too small to be measured")
#rating <- subset(rating, !is.na(rating$FIPS_County_Code))

#column selection
rating <- subset(rating, select = c("Contract_ID", "Star_Rating"))
rating <- rename(rating, c("Contract_ID" = "contract_id"))
colnames(rating)
ratingFinal <- rbind.fill(llFinal, rating)
#ratingFinal <- rbind.fill(medicareData, rating)
#ratingFinal <- merge(medicareData, rating)
ratingFinal <- subset(ratingFinal, ratingFinal$copay_amt_inn_prefrd != "")
write.csv(ratingFinal, "RatingFinal.csv")

ratingFinal$Star_Rating

#sample in a way for training = 80% and test sets = 20%
sample_size <- floor(0.8 * nrow(ratingFinal));
training_index<- sample(seq_len(nrow(ratingFinal)), size = sample_size);
train <- ratingFinal[training_index,];
test <- ratingFinal[-training_index,];

library(C50);

#specify the columns to use as predictors
predictors <- c("contract_id", "plan_id","plan_cvrg_typ_id","mnthly_prm", "ann_ddctbl", "copay_amt_inn_prefrd", "coins_amt_inn_prefrd", "copay_amt_mail_ordr_prefrd",
                "coins_amt_mail_ordr_prefrd");
#fit the model
train[,"copay_amt_inn_prefrd"] <- sapply(train[,"copay_amt_inn_prefrd"], as.character);
train[,"coins_amt_inn_prefrd"] <- sapply(train[,"coins_amt_inn_prefrd"], as.character);
train[,"copay_amt_mail_ordr_prefrd"] <- sapply(train[,"copay_amt_mail_ordr_prefrd"], as.character);
train[,"coins_amt_mail_ordr_prefrd"] <- sapply(train[,"coins_amt_mail_ordr_prefrd"], as.character);
#train[,"Star_Rating"] <- sapply(train[,"Star_Rating"], as.character);
#str(train$Star_Rating)
train$Star_Rating <- gsub(c("1 out of 5 stars"), c("1"), train$Star_Rating, fixed=TRUE)
train$Star_Rating <- gsub(c("2 out of 5 stars"), c("2"), train$Star_Rating, fixed=TRUE)
train$Star_Rating <- gsub(c("3 out of 5 stars"), c("3"), train$Star_Rating, fixed=TRUE)
train$Star_Rating <- gsub(c("4 out of 5 stars"), c("4"), train$Star_Rating, fixed=TRUE)
train$Star_Rating <- gsub(c("5 out of 5 stars"), c("5"), train$Star_Rating, fixed=TRUE)

train[,"Star_Rating"] <- sapply(train[,"Star_Rating"], as.factor);
model<- C5.0.default(x = train[,predictors], y = train$Star_Rating);
summary(model);
plot(model);

#predict
pred<- predict(model, newdata = test);
length(pred);

evaluation <- cbind(test, pred);
dim(evaluation);

#evaluate
evaluation$correct <- ifelse(evaluation$survive == evaluation$pred, 1, 0);
ncol(evaluation);
head(evaluation);

#accuracy
sum(evaluation$correct)/nrow(evaluation);

