# ----------------------------
# 1. Install and Load Required Packages
# ----------------------------
install.packages("caret")   # if not already installed
install.packages("ranger")  # fast random forest implementation
library(caret)
library(ranger)

# ----------------------------
# 2. Read in the Data
# ----------------------------
# Define column names (as per the UCI Adult dataset documentation)
col_names <- c("age", "workclass", "fnlwgt", "education", "education_num", 
               "marital_status", "occupation", "relationship", "race", "sex", 
               "capital_gain", "capital_loss", "hours_per_week", "native_country", "income")

# Read training data (adult.data)
adult_train <- read.csv("adult.data", header = FALSE, strip.white = TRUE)
names(adult_train) <- col_names

# Read test data (adult.test)
# Note: adult.test might include an extra header row or special formatting. We skip the first row.
adult_test <- read.csv("adult.test", header = FALSE, skip = 1, strip.white = TRUE)
names(adult_test) <- col_names

# ----------------------------
# 3. Data Cleaning
# ----------------------------
# Replace "?" with NA for missing values
adult_train[adult_train == "?"] <- NA
adult_test[adult_test == "?"]   <- NA

# Convert the target variable 'income' to factor (ensure levels match)
adult_train$income <- factor(adult_train$income, levels = c("<=50K", ">50K"))
adult_test$income  <- factor(adult_test$income, levels = c("<=50K", ">50K"))

# Convert selected categorical variables to factors (if needed)
adult_train$workclass <- as.factor(adult_train$workclass)
adult_test$workclass  <- as.factor(adult_test$workclass)
adult_train$native_country <- as.factor(adult_train$native_country)
adult_test$native_country  <- as.factor(adult_test$native_country)

# ----------------------------
# 4. One-Hot Encoding (OHE)
# ----------------------------
# Create a dummyVars object excluding the outcome variable 'income'
dmy <- dummyVars(income ~ ., data = adult_train, fullRank = TRUE)

# Transform both training and test sets
adult_train_ohe <- data.frame(predict(dmy, newdata = adult_train))
adult_test_ohe  <- data.frame(predict(dmy, newdata = adult_test))

This Step 14:34
# Add the target variable back to the datasets
adult_train_ohe$income <- adult_train$income
adult_test_ohe$income  <- adult_test$income

# ----------------------------
# 5. Cross-Validation Setup Using caret with Ranger
# ----------------------------
# Define a 5-fold cross-validation scheme
ctrl <- trainControl(method = "cv", number = 5, verboseIter = TRUE)

# Set seed for reproducibility
set.seed(123)

# Train a model using ranger via caret
# Here, tuneLength = 3 instructs caret to try 3 different settings for hyperparameters
model_ranger <- train(
  income ~ .,              # 'income' is the target; all other columns are predictors
  data = adult_train_ohe,
  method = "ranger",       # Use the 'ranger' method (fast random forest)
  trControl = ctrl,        # Apply the CV scheme defined above
  tuneLength = 3           # Automatically explore a few hyperparameter combinations
)

# Display the model details and the best tuning parameters found
print(model_ranger)

# ----------------------------
# 6. Final Evaluation on the Test Set
# ----------------------------
# Predict using the final model on the one-hot encoded test set
test_preds <- predict(model_ranger, newdata = adult_test_ohe)

# Compute the confusion matrix and accuracy
conf_matrix <- confusionMatrix(test_preds, adult_test_ohe$income)
print(conf_matrix)
