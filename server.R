library(shiny)
# file path for the final data set
filepath <- "./data/final_data_v2.csv"
# read files
if(!exists(filepath)) {
    data <- read.csv(file = filepath)
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
            logsitic_regression_model = glm(formula = sentiment ~ ., family = binomial(link = 'logit'), data = train)
            lr_pred <- predict(logsitic_regression_model, newdata = predictors, type = "response")
            lr_rating <- paste("The Logistic Regression Probability: ", round(lr_pred, 2))
            
            # Decision Tree Modeling
            # decision_tree_model <-
            # dt_pred <- 
            # dt_rating <- 
            # Artificial Neural Network Modeling
            # neural_network_model <- 
            # nn_pred <- 
            # nn_rating <- 
            # Naive Bayes Modeling
            
            HTML(paste(lr_rating, sep = '<br/>'))
        })
    }
)