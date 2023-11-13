*******************************************************
** Copyright levies and cloud storage				 **
** Ex-ante policy evaluation with a field experiment **
*******************************************************

global path "YOUR_PATH"

cd "$path/data"
global outputpath="../output"


** Figure 1
run ../do/figure_1.do

** Figure 2
run ../do/figure_2.do

** Figure 3
run ../do/figure_3.do

** Figure 4
run ../do/figure_4.do

** Figure 5 and 6
run ../do/figure_5_6.do

** Figures A1 and A2
run ../do/figure_A1_A2.do

** Tables 3, 4, 5, A1, A2, A3 and A4
run ../do/table_3_4_5_A1_A2_A3_A4.do

** Tables 1 and 2
run ../do/table_1_2.do

