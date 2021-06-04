library(readr)
library(ggplot2)
library(dplyr)
library(tidyr)
library(scales)
library(data.table)
library(grid)
library(gridExtra)
library(gtable)
library(lemon)
library(xtable)
library(HDInterval)

# read data
pop_info <- fread("../Data/PopInfo/pop_info.csv", header = T)
hdir <- "../Results/"
date_seq <- seq(as.Date("2020-09-02"), as.Date("2020-12-18"), by = "day")
int_seq <- "superspreading_event"
name_csv <- paste0("pos_test_date_count_int",int_seq,".csv")
dir_csv <- paste0(hdir,name_csv)
ic_all <-  fread(dir_csv, header = T)  %>% mutate(Date=date_pos_test, OffCampus=`off-campus-count`,
                                                  OnCampus=`on-campus-count`)%>% select(Date,sim_num, OffCampus, OnCampus)
ic_all$Date <- as.Date(ic_all$Date)
name_csv <- paste0("quarantine_network_count_int",int_seq,".csv")
dir_csv <- paste0(hdir,name_csv)
quar_index <- fread(dir_csv, header = T) %>% mutate(Date=date_quarantined) %>% select(-c(V1,date_quarantined) )
quar_index$Date <- as.Date(quar_index$Date)

# number of simulation trials
n_sims <- 1000

# prediction periods
pred_period_seq <- seq(as.Date("2020-09-30"), as.Date("2020-11-20"), by = "day") 
n_ahead <- 9
pred_period <- lapply(1:length(pred_period_seq),  function(i) seq(pred_period_seq[i], pred_period_seq[i]+n_ahead, by = "day"))
ratio_period <- lapply(1:length(pred_period), function(i) seq(as.Date("2020-09-03"), pred_period[[i]][1]-1, by = "day"))
date_quar <- pred_period_seq + n_ahead 

# real quarantine counts 
quar_on_campus <- quar_index %>% mutate(count=q_on_ind_on+q_on_ind_off+q_on_ind_on_off)  %>% select(Date,sim_num,count)
quar_real <- sapply(1:length(pred_period), function(i) quar_on_campus %>% filter(Date %in%pred_period[[i]])%>% group_by(sim_num) %>% summarise(cumcount=sum(count) )  %>% ungroup  %>% summarise(means=mean(cumcount)) %>% unlist)

# real diagnosed counts
ic_real <- lapply(1:length(pred_period), function(i) ic_all %>% filter(Date %in%pred_period[[i]]) %>% group_by(sim_num) %>% summarise(OnCampus=sum(OnCampus),OffCampus=sum(OffCampus) ) )

# estimate ratios
quar_count <- lapply(1:length(pred_period), function(i)  quar_index %>% select(-c(q_off_ind_on_off,q_on_ind_on_off))%>% filter(Date %in%ratio_period[[i]])%>%  
                       group_by(sim_num) %>%  summarise(q_off_ind_off=sum(q_off_ind_off),q_off_ind_on=sum(q_off_ind_on),q_on_ind_off=sum(q_on_ind_off),q_on_ind_on=sum(q_on_ind_on)) )

ic_count <- lapply(1:length(pred_period), function(i) ic_all %>%filter(Date %in%ratio_period[[i]]) %>%
                     group_by(sim_num) %>% summarise(OffCampus=sum(OffCampus),OnCampus=sum(OnCampus) ) )

ratio_est <- lapply(1:length(pred_period), function(i) merge(quar_count[[i]],ic_count[[i]],all=TRUE) %>% 
                      mutate(ratio2=ifelse(OffCampus>0,q_on_ind_off/OffCampus,0) ,ratio1=ifelse(OnCampus>0,q_on_ind_on/OnCampus,0) ) %>%
                      select(sim_num,ratio2,ratio1)  )

# predicted diagnosed counts (a superspreading event on Oct 31)
ic_pred <- lapply(1:length(pred_period), function(i) ic_all %>% filter(Date %in%( pred_period[[i]] -length(pred_period[[i]]) ) )%>% group_by(sim_num) %>%
                    summarise(OnCampus=sum(OnCampus),OffCampus=sum(OffCampus) ) )

party_date <- which(pred_period_seq=="2020-10-31")
party_size <- 20
party_extra <- data.frame(sim_num=0:(n_sims-1), OnCampus_party=party_size,OffCampus_party=party_size) 
weight <- c(seq(.1,.7,.1),seq(.7,.1,length.out = 8)[-1])
weight <- weight/sum(weight)

ic_pred_party <- ic_pred 
period_change1 <- (party_date+1):(party_date+length(weight))  
for (i in 1:length(period_change1) ) {
  ic_pred_party[[period_change1[i] ]] <- full_join(ic_pred[[period_change1[1]]], party_extra ,by="sim_num") %>% 
    mutate(OnCampus=OnCampus+OnCampus_party*sum(weight[i:min(i+n_ahead,length(weight))]),OffCampus=OffCampus+OffCampus_party*sum(weight[i:min(i+n_ahead,length(weight))]) ) %>%
    select(sim_num,OnCampus,OffCampus)
  
}
period_change2 <- (party_date+1+length(weight)):(min(length(pred_period_seq), party_date+length(weight)+n_ahead)) 
for (i in 1:length(period_change2) ) {
  ic_pred_party[[period_change2[i] ]] <- full_join(ic_pred[[period_change2[i]]], party_extra ,by="sim_num") %>% 
    mutate(OnCampus=OnCampus-OnCampus_party*sum(weight[(length(weight)-n_ahead-1+i):length(weight)]),OffCampus=OffCampus-OffCampus_party*sum(weight[(length(weight)-n_ahead-1+i):length(weight)]) ) %>%
    select(sim_num,OnCampus,OffCampus)
  
}
period_change3 <- (party_date+1-n_ahead):party_date  
for (i in 1:length(period_change3) ) {
  ic_pred_party[[period_change3[i] ]] <- full_join(ic_pred[[period_change3[i]]], party_extra ,by="sim_num") %>% 
    mutate(OnCampus=OnCampus+OnCampus_party*sum(weight[1:i]),OffCampus=OffCampus+OffCampus_party*sum(weight[1:i]) ) %>%
    select(sim_num,OnCampus,OffCampus)
  
}  

# predicted quarantine counts (a superspreading event on Oct 31)
quar_pred <- sapply(1:length(pred_period), function(i) merge(ratio_est[[i]],ic_pred_party[[i]]) %>% mutate(count=(ratio1*OnCampus+ratio2*OffCampus) ) %>% 
                      summarise(means=mean(count) ) %>% unlist ) 

# figure 1(b)
date_all<- seq(as.Date("2020-09-02"), as.Date("2020-12-01"), by = "day")
data_long <- ic_all %>% mutate(Count=OffCampus+OnCampus) %>% group_by(Date) %>% summarise(Count=mean(Count))%>% select(Date,Count)%>% filter(Date%in%date_all) %>% 
  mutate(Type="Diagnosed case counts") %>% add_row(Date=date_quar,Count=quar_real , Type="Reality")%>%
  add_row(Date=date_quar,Count=quar_pred, Type="Prediction (superspreading event)") 

ggplot() + geom_bar(data=data_long %>% subset(Type=="Diagnosed case counts"), aes(y=Count,x=Date),
                         stat="identity", width = 0.75) + 
  geom_line(data = data_long %>% subset(Type!="Diagnosed case counts"), aes(y=Count,x=Date,linetype =Type))+
  labs(color  = "Quarantine counts") +scale_x_date(date_breaks = "15 day", date_labels =  "%b-%d") +
  theme_minimal(base_size = 12) +xlab("") + ylab("") +
  theme(legend.title = element_blank(), legend.position = c(0.15, 0.85),
        plot.title = element_text(hjust = 0.5),
        panel.grid.minor = element_blank(),
        panel.border = element_rect(fill=NA,color="black", size=0.5),
        panel.background = element_blank())
