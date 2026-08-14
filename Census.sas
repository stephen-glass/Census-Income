data SOR3008.Census;
    length
        age 8
        workclass $30
        fnlwgt 8
        education $25
        education_num 8
        marital_status $30
        occupation $30
        relationship $20
        race $25
        sex $7
        capital_gain 8
        capital_loss 8
        hours_per_week 8
        native_country $40
        income $7
    ;
    infile "/home/u64128910/SOR3008/AD.csv" dsd firstobs=2 dlm=',' missover;
    input
        age
        workclass $
        fnlwgt
        education $
        education_num
        marital_status $
        occupation $
        relationship $
        race $
        sex $
        capital_gain
        capital_loss
        hours_per_week
        native_country $
        income $;
run;

data SOR3008.Census_Clean;
    set SOR3008.Census;
    if workclass = '' then delete;
    if occupation = '' then delete;
    if native_country = '' then delete;
    if education = '' then delete;
    if marital_status = '' then delete;
    if relationship = '' then delete;
    if race = '' then delete;
    if sex = '' then delete;
    if income = '' then delete;
    
    * Check numeric variables;
    if age = . then delete;
    if fnlwgt = . then delete;
    if education_num = . then delete;
    if capital_gain = . then delete;
    if capital_loss = . then delete;
    if hours_per_week = . then delete;
run;

proc freq data=SOR3008.Census_clean;
    tables workclass education marital_status occupation 
           relationship race sex native_country income 
           / plots=freqplot(scale=percent);
run;
data SOR3008.Census_1;
    set SOR3008.Census_clean;
    
    * Count how many "?" per record;
    q_count = (workclass = "?") + (occupation = "?") + (native_country = "?");
    
    * Income binary;
    income_binary = (income = ">50K");
run;
proc freq data=SOR3008.Census_1;
    tables q_count / missing;
    title "Number of Missing Values per Record";
run;
* Calculate overall rate;
proc means data=SOR3008.Census_1 mean n;
    var income_binary;
    format income_binary percent8.2;
run;

proc freq data=SOR3008.Census_1;
    tables q_count / missing;
    title "Number of Missing Values per Record";
run;

proc means data=SOR3008.Census_1 mean;
    class q_count;
    var income_binary;
    title "Income >50K Rate by Number of Missing Values";
run;

proc means data=SOR3008.Census_1 mean;
    class workclass;
    var income_binary;
    title "Original Workclass - Income >50K Rates";
run;

proc means data=SOR3008.Census_1 mean;
    class occupation;
    var income_binary;
    title "Original Occupation - Income >50K Rates";
run;

proc means data=SOR3008.Census_1 mean;
    class education;
    var income_binary;
    title "Original Education - Income >50K Rates";
run;

proc means data=SOR3008.Census_1 mean;
    class marital_status;
    var income_binary;
    title "Original Marital Status - Income >50K Rates";
run;

data SOR3008.Census_2;
    set SOR3008.Census_1;
    
    /* WORKCLASS GROUPINGS - based on income rates */
    length work_group $30;
    select (workclass);
        when ("?") work_group = "Missing";
        when ("Self-emp-inc") work_group = "Self-Employed High Income";    
        when ("Federal-gov") work_group = "Federal Government";           
        when ("Local-gov", "State-gov") work_group = "Local/State Government"; 
        when ("Self-emp-not-inc", "Private") work_group = "Private/Low Self-Employed"; 
        when ("Never-worked", "Without-pay") work_group = "Not Working";   
        otherwise work_group = "Other";
    end;
    
    * OCCUPATION GROUPINGS - based on income rates ;
    length occ_group $30;
    select (occupation);
        when ("?") occ_group = "Missing";
        when ("Exec-managerial", "Prof-specialty") occ_group = "Professional/Managerial"; 
        when ("Protective-serv", "Tech-support") occ_group = "Protective/Tech"; 
        when ("Sales", "Craft-repair") occ_group = "Sales/Crafts";       
        when ("Adm-clerical", "Transport-moving", "Machine-op-inspct") occ_group = "Admin/Transport/Labor";
        when ("Farming-fishing", "Armed-Forces") occ_group = "Farming/Military"; 
        when ("Handlers-cleaners", "Other-service") occ_group = "Service/Labor"; 
        when ("Priv-house-serv") occ_group = "Private Household";           
        otherwise occ_group = "Other";
    end;
    
    /* EDUCATION GROUPINGS - based on income rates */
    length edu_group $25;
    select (education);
        when ("Preschool", "1st-4th", "5th-6th", "7th-8th", "9th", "10th", "11th", "12th") 
            edu_group = "Less than High School";          
        when ("HS-grad") 
            edu_group = "HS Graduate";         
        when ("Some-college", "Assoc-acdm", "Assoc-voc") 
            edu_group = "Some College/Associate";         
        when ("Bachelors") 
            edu_group = "Bachelors";                    
        when ("Masters", "Prof-school", "Doctorate") 
            edu_group = "Graduate Degree";                 
        otherwise edu_group = "Other";
    end;
    
    /* MARITAL STATUS GROUPINGS - based on income rates */
    length marital_group $25;
    select (marital_status);
        when ("Married-civ-spouse", "Married-AF-spouse") 
            marital_group = "Married";                    
        when ("Never-married") 
            marital_group = "Never Married";            
        when ("Divorced", "Separated", "Widowed", "Married-spouse-absent") 
            marital_group = "Previously/Not Living with Spouse"; 
        otherwise marital_group = "Other";
    end;
    
    /* RACE GROUPING - simplify */
    length race_group $15;
    select (race);
        when ("White") race_group = "White";
        when ("Black") race_group = "Black";
        when ("Asian-Pac-Islander") race_group = "Asian";
        otherwise race_group = "Other";
    end;
    
    * AGE GROUPING ;
    length age_group $10;
    if age < 30 then age_group = "<30";
    else if age < 45 then age_group = "30-44";
    else if age < 60 then age_group = "45-59";
    else age_group = "60+";
    
    * HOURS GROUPING;
    length hours_group $10;
    if hours_per_week < 30 then hours_group = "Part";
    else if hours_per_week < 41 then hours_group = "Full";
    else hours_group = "Overtime";
    
    * COUNTRY GROUPING ;
    length country_group $10;
    if native_country = "?" then country_group = "Missing";
    else if native_country = "United-States" then country_group = "USA";
    else country_group = "Non-USA";
run;



* Calculate income rates by work group;
proc means data=SOR3008.Census_2;
    class work_group;
    var income_binary;
    output out=income_rates_work mean=income_rate n=count;
run;

* Plot income rates by work group;
proc sgplot data=income_rates_work;
    vbar work_group / response=income_rate;
    xaxis label="Work Group" fitpolicy=rotate;
    yaxis label="Proportion with Income >50K" values=(0 to 0.6 by 0.1);
    title "Proportion with Income >50K by Work Group";
run;

* Calculate income rates by occupation group;
proc means data=SOR3008.Census_2;
    class occ_group;
    var income_binary;
    output out=income_rates_occ mean=income_rate n=count;
run;

* Plot income rates by occupation group;
proc sgplot data=income_rates_occ;
    vbar occ_group / response=income_rate;
    xaxis label="Occupation Group" fitpolicy=rotate;
    yaxis label="Proportion with Income >50K" values=(0 to 0.6 by 0.1);
    title "Proportion with Income >50K by Occupation Group";
run;

* Calculate income rates by education group;
proc means data=SOR3008.Census_2;
    class edu_group;
    var income_binary;
    output out=income_rates_edu mean=income_rate n=count;
run;

* Plot income rates by education group;
proc sgplot data=income_rates_edu;
    vbar edu_group / response=income_rate;
    xaxis label="Education Group" fitpolicy=rotate;
    yaxis label="Proportion with Income >50K" values=(0 to 0.8 by 0.1);
    title "Proportion with Income >50K by Education Group";
run;

* Calculate income rates by age group;
proc means data=SOR3008.Census_2;
    class age_group;
    var income_binary;
    output out=income_rates_age mean=income_rate n=count;
run;

* Plot income rates by age group;
proc sgplot data=income_rates_age;
    vbar age_group / response=income_rate;
    xaxis label="Age Group";
    yaxis label="Proportion with Income >50K" values=(0 to 0.4 by 0.1);
    title "Proportion with Income >50K by Age Group";
run;



* Test difference in income rates between male and female;
proc ttest data=SOR3008.Census_2;
    class sex;
    var income_binary;
    where sex in ('Male', 'Female');
    title "T-Test: Income >50K Rate Difference by Sex";
run;

* Test difference in income rates between different age groups;
proc freq data=SOR3008.Census_2;
    tables age_group * income / chisq expected nocol nopercent;
run;

* Test difference in income rates between education groups;
proc freq data=SOR3008.Census_2;
    tables edu_group * income / chisq expected nocol nopercent;
run;


* Test difference in income rates between work groups;
proc freq data=SOR3008.Census_2;
    tables work_group * income / chisq expected nocol nopercent;
run;


* Test difference in income rates between occupation groups;
proc freq data=SOR3008.Census_2;
    tables occ_group * income / chisq expected nocol nopercent;
run;


* Test difference in income rates between marital status groups;
proc freq data=SOR3008.Census_2;
    tables marital_group * income / chisq expected nocol nopercent;
run;

proc export data=SOR3008.Census_2
    outfile="/home/u64128910/SOR3008/Census.csv"
    dbms=csv
    replace;
run;

proc means data=SOR3008.Census_2 mean;
    var income_binary;
    title "UNWEIGHTED: Sample Rate";
run;

proc surveymeans data=SOR3008.Census_2;
    weight fnlwgt;
    var income_binary;
    title "WEIGHTED: Population Rate";
run;

proc surveyselect data=SOR3008.Census_2 method=srs samprate=0.7 
                  out=CensusSplit outall;
    title "Splitting Census Data: 70% Training / 30% Test";
run;

data training test;
    set CensusSplit;
    if selected = 1 then output training;
    else output test;
run;

proc logistic data=training descending;
    * Define categorical variables and reference groups;
    class sex (ref='Female') race_group (ref='White') 
          work_group (ref='Private/Low Self-Employed')
          occ_group (ref='Service/Labor') edu_group (ref='HS Graduate')
          marital_group (ref='Never Married') age_group (ref='<30')
          hours_group (ref='Full') country_group (ref='USA') / param=ref;
          
    model income_binary = age_group sex race_group work_group 
                         occ_group edu_group marital_group 
                         hours_group country_group education_num;        
                         
    output out=trainPredLR p=predProb;
    score data=test out=testPredLR;
    ods output Association=trainAUC_LR;
    roc;
    title "Logistic Regression: Predicting Income >50K";
run;

Apply the 0.5 threshold to the training predictions;
data trainEvalLR;
    set trainPredLR;
    Actual = income_binary;
    Predicted = (predProb >= 0.50);
run;

* 3. Generate the Training Confusion Matrix;
title "Confusion Matrix - Logistic Regression (TRAINING Data)";
proc freq data=trainEvalLR;
    tables Actual*Predicted / norow nocol nopct;
run;

/* Score Logistic Regression Test Data */
data lr_eval;
    set testPredLR;
    Actual = income_binary;
    Predicted = (P_1 >= 0.50); /* Probability cutoff */
run;

proc freq data=lr_eval;
   tables Actual*Predicted / norow nocol nopct;
   title "Confusion Matrix: Logistic Regression (Test Data)";
run;

proc hpsplit data=training seed=12345 maxdepth=10;
   class income_binary sex race_group work_group occ_group 
         edu_group marital_group age_group hours_group country_group;
         
   model income_binary (event='1') = education_num age_group sex race_group 
                                    work_group occ_group edu_group 
                                    marital_group hours_group country_group;
                                    
   grow entropy;
   prune costcomplexity; 
   output out=fullTreePred;
   code file='/home/u64128910/SOR3008/census_tree_model.sas'; 
   title "Building Census Classification Tree";
run;

/* Apply Tree to Test Data */
data testTreePred;
   set test;
   %include "/home/u64128910/SOR3008/census_tree_model.sas";
run;

/* Tree Performance Evaluation */
data tree_eval;
   set testTreePred;
   Actual    = income_binary;
   Predicted = (P_income_binary1 >= 0.50);
run;

proc freq data=tree_eval;
   tables Actual*Predicted / norow nocol nopct;
   title "Confusion Matrix: Classification Tree (Test Data)";
run;

/* AUC for Logistic Regression Test Data */
proc logistic data=lr_eval;
   model Actual(event='1') = P_1;
   roc pred=P_1;
   ods output ROCAssociation=auc_lr_final;
run;

/* AUC for Classification Tree Test Data */
proc logistic data=tree_eval;
   model Actual(event='1') = P_income_binary1;
   roc pred=P_income_binary1;
   ods output ROCAssociation=auc_tree_final;
run;

/* Combine and Print Results */
data final_comparison;
    set auc_lr_final(rename=(Area=LR_AUC) in=a)
        auc_tree_final(rename=(Area=Tree_AUC) in=b);
    where ROCModel = 'Model';
    keep LR_AUC Tree_AUC;
run;

proc print data=final_comparison;
    title "Final Coursework Comparison: Model AUC Values";
run;


