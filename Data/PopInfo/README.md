# Dataset example

This directory contains a comma-separated file that describe the artificial university population. The population of this university consists of 2000 undergraduate, 1000 masters and 500 PhD students as well as 250 faculty members.

### pop_info.csv
This file describes the artificial university population. In this example only students and faculty are present. <br>
7 columns:<br>
id (numeric) - student or faculty ID;<br>
age (numeric) - age; for faculty age "brackets" are used - 35 for [30-39], 45 for [40-49], etc.;<br>
sex (binary) - gender identifier (0 or 1);<br>
Affilation (numeric) - 1 - student; 2 - faculty; 3 - staff; 4 - affiliate;<br>
Residence (numeric) - 0 - does not live on campu, 1 - lives in a small dorm, 2 - lives in a large dorm;<br>
TestCategory (numeric) - risk group ( 1 - highest risk, 4 - lowest risk). The risk group is determined by a number of factors, i.e. student is living on campus, faculty or staff meeting (or not) with students, person taking public transportation, etc. ;<br>
Undergrad (binary) - 1 - undergraduate student, 0 - otherwise

Variables *Affilation*, *Residence*, *TestCategory* and *Undergrad* are used to run specific interventions.



