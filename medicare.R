rm(list = ls());
setwd("C:/MIS510/Labs/Independent/2015Med2000_flatfiles")

#cost sharing
costSharingData <- read.csv("vwPlanDrugsCostSharing.csv", na.strings = c('NULL', 'NA'))
costSharingData <- subset(costSharingData,  costSharingData$copay_amt_inn_prefrd != "Information Not Available")
costSharingData <- subset(costSharingData,  costSharingData$copay_amt_mail_ordr_prefrd != "Information Not Available")
costSharingData <- subset(costSharingData, 
                          select = c("contract_id", "plan_id","plan_cvrg_typ_id","mnthly_prm", "ann_ddctbl", "copay_amt_inn_prefrd", "coins_amt_inn_prefrd", "copay_amt_mail_ordr_prefrd",
                            "coins_amt_mail_ordr_prefrd"))

#tier cost
drugTierData <- read.csv("vwPlanDrugTierCost.csv")

drugTierData <- subset(drugTierData, drugTierData$Language == "English")
mailD <- grep ("Mail", drugTierData$tier_type_desc, value=TRUE, fixed=TRUE)

drugTierData <- subset(drugTierData, drugTierData$tier_type_desc == mailD[1] | drugTierData$tier_type_desc == mailD[2] | drugTierData$tier_type_desc == mailD[3] | drugTierData$tier_type_desc == mailD[4] |
                         drugTierData$tier_type_desc == mailD[5] | drugTierData$tier_type_desc == mailD[6] )


drugTierData <- subset(drugTierData, drugTierData$cost_share_pref != "Information Not Available")
drugTierData <- subset(drugTierData, drugTierData$cost_share_gen != "Information Not Available")
drugTierData <- subset(drugTierData, select = c("contract_id", "plan_id","tier_label"))

finalData <- merge(costSharingData, drugTierData)

setwd("../2015StarRatings_flatfiles/")

rating <- read.csv("vwStarRating_Measures.csv")
rating <- subset(rating, rating$Language == "English")
rating <- subset(rating, rating$Star_Rating != "Not enough data available" )
rating <- subset(rating, rating$Star_Rating != "No data available")
rating <- subset(rating, rating$Star_Rating != "Plan not required to report measure")
rating <- subset(rating, rating$Star_Rating != "Benefit not offered by plan")
rating <- subset(rating, rating$Star_Rating != "Plan too new to be measured")
rating <- subset(rating, rating$Star_Rating != "Plan too small to be measured")

#column selection
rating <- subset(rating, select = c("Contract_ID", "Star_Rating"))
rating <- rename(rating, c("Contract_ID" = "contract_id"))

ratingFinal <- merge(finalData, rating)
