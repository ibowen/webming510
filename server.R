library(shiny)
library(C50)
library(e1071)
library (nnet)
# file path for the final data set
filepath <- "./data/final_data_v2.csv"
# read files
if(!exists(filepath)) {
    data <- read.csv(file = filepath)
    # remove neutral 4 points, and change the label into 1 and 0
    data_rm4 <- data[data$Star_Rating_Current != 4, ]
    # transfer the label into binary value
    data_rm4$sentiment <- ifelse(data_rm4$Star_Rating_Current > 4,1,0)
    # transfer sentiment to factor variables
    data_rm4$sentiment <- factor(data_rm4$sentiment, levels = c(0,1), labels = c('Bad','Good'))
    # subset the need columns for modeling
    colnames <- c('experience', 'spec_count', 'unemployment_rate', 'averge_income', 'avgerage_physician', 'tier_label', 'mnthly_prm', 'ann_ddctbl', 'copay_max', 'coin_max', 'sentiment')
    data_rm4 <- data_rm4[, colnames]
}


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
            # Logistic Regression Modeling
            logsitic_regression_model = glm(formula = sentiment ~ ., family = binomial(link = 'logit'), data = data_rm4)
            lr_pred <- predict(logsitic_regression_model, newdata = predictors, type = "response")
            #lr_rating <- paste("The Logistic Regression Probability: ", round(lr_pred, 2))
            lr_rating <- paste("The Logistic Regression Probability: ", ifelse(lr_pred > 0.5, 'Good', 'Bad'))

            # Decision Tree Modeling
            decision_tree_model <- C5.0.default(x = data_rm4[,colnames], y = data_rm4$sentiment)
            dt_pred <- predict(decision_tree_model, newdata = predictors)
            dt_rating <- paste("The Decision Tree Prediction: ", dt_pred)

            # Artificial Neural Network Modeling

            neural_network_model <- nnet(formula =  sentiment~.-sentiment, data =data_rm4, decay = 0.5, size = 6)
            nn_pred <- predict(neural_network_model, newdata = predictors, type='class')
            nn_rating <- paste("The Neural Network Prediction: ", ifelse(lr_pred > 0.5, 'Good', 'Bad'))

            # Naive Bayes Modeling
            naive_bayes_model <- naiveBayes(sentiment~ . , data=data_rm4)
            nb_pred <- predict(naive_bayes_model, newdata = predictors, type = 'class')
            nb_rating <- paste("The Naive Bayes Prediction: ", nb_pred)


            HTML(paste(lr_rating, dt_rating, nb_rating, nn_rating, sep = '<br/>'))
        })
    }
)