library(shiny)
library(ggplot2)
library(stats)
# file path for the final data set
filepath <- "./data/final_data_v2.csv"
# read files
if(!exists(filepath)) {
    data <<- read.csv(file = filepath)
}

# remove neutral 4 points, and change the label into 1 and 0
data_rm4 <- data[data$Star_Rating_Current != 4, ]
# transfer the label into binary value
data_rm4$sentiment <- ifelse(data_rm4$Star_Rating_Current > 4,1,0)
# subset the need columns for modeling
colnames <- c('experience', 'spec_count', 'unemployment_rate', 'averge_income', 'avgerage_physician', 'tier_label', 'mnthly_prm', 'ann_ddctbl', 'copay_max', 'coin_max', 'sentiment')
data_rm4 <- data_rm4[, colnames]
# subset the train and test data sets
set.seed(510)
sample_size <- floor(0.8 * nrow(data_rm4))
training_index <- sample(seq_len(nrow(data_rm4)), size = sample_size)
train <- data_rm4[training_index,]
# train the model
logistic_regession_model <- glm(formula = sentiment ~ ., family = binomial(link = 'logit'), data = train)
predict(logistic_regession_model, newdata = test[1,], type = 'response')

shinyServer(
    function(input, output){
        # internal predictors
        output$internal <- renderUI({
            tier <- paste("Tier Number: ", input$tier)
            premium <- paste("Monthy Premium($): ", input$premium)
            deductible <- paste("Annualy Deductible($): ", input$deductible)
            copayment <- paste("Maximium Copayment Rate(%): ", input$copayment)
            coinsurance <- paste("Maximium Coinsurance Rate(%): ", input$coinsurance)
            HTML(paste(tier, premium, deductible, copayment, coinsurance, sep = '<br/>'))
        })
        # external predictors
        output$external <- renderUI({
            experience <- paste("Average Work Experience(years): ", input$experience)
            unemployment <- paste("Unemployment Rate(%): ", input$unemployment)
            income <- paste("Average Income(,000$): ", input$income)
            physician <- paste("Average Citizens per Physician: ", input$physician)
            spec_type <- paste("Physician Speciaty Types in County: ", input$spec_type)
            HTML(paste(experience, unemployment, income, physician, spec_type, sep = '<br/>'))
        })
        output$ratings <- renderUI({
            predictors <- data.frame(input$experience, input$spec_type, input$unemployment, input$income, input$physician, input$tier, input$premium, input$deductible, input$copayment, input$coinsurance, 0)
            colnames(predictors) <- colnames
            predictions <- predict(logistic_regession_model, newdata = predictors, response = "response")
            rating <- paste("The Final Rating Score: ", predictions)
            HTML(paste(predictions, sep = '<br/>'))
        })
        # plotting the model
        # output$predictions <- renderPlot({
        #     # Sample the source data
        #     # inNEI <- sample(1:nrow(NEI), input$sample_size, replace = FALSE)
        #     # NEI <- NEI[inNEI, ]
        #     # NEI_2 <- NEI[NEI$year %in% input$year, ]
        #     # NEI_2 <- NEI_2[NEI_2$type %in% input$type, ]
        #     
        # # test = data.frame([0,1,3,5,6,7])
        # #     
        # # ggplot(data = test, aes(x = , y = Emissions, colour = type)) +
        # #     geom_point(size = 15, alpha = 0.5) +
        # #     xlab("years") +
        # #     ylab("PM2.5 Emissions tons") +
        # #     ggtitle("PM2.5 Emissions by year and by type")
        # })
    }
)


