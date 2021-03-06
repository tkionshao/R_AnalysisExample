# Step 1 建立MySQL連結
library(RJDBC)
# 啟動Driver
drv <- JDBC("com.mysql.jdbc.Driver",
            "E:\\MegaSync\\MEGAsync\\R\\tryByself\\mysql-connector-java-5.1.46.jar"
            
)
# 設定連線
# DB name: test123, login id: root, login password: tony, 預設port 3306
conn <- dbConnect(drv,
                  "jdbc:mysql://172.104.90.53:3306/iii",
                  "iii",
                  "iii@WSX1qaz"
                  
)


# Step 2 整理機器學習演算法所需的資料 allitems
sensor <- dbGetQuery(conn,"select * from sensor")
airquality <- dbGetQuery(conn,"select * from airquality ")
# 安裝sqldf,利用SQL語法整理資料
install.packages("sqldf")
library(sqldf)

# 將sensor收集的資料整理成 月, 日, 當日平均溫度, 當日平均濕度,然後透過月、日與airquality 作資料勾稽(Left join)
df_sensor <- sqldf("SELECT cast(substr(trim(dt),7,1) as int) month
                     ,cast(substr(trim(dt),9,2) as int) day
                     ,avg(temperature) avg_temperature
                     ,avg(humidity) avg_humidity
                     FROM sensor
                     group by 
                     cast(substr(trim(dt),7,1) as int)
                     ,cast(substr(trim(dt),9,2) as int)
                     having cast(substr(trim(dt),7,1) as int) <>0
                     ")

df_allitems <- sqldf(" select a.*,b.avg_temperature,b.avg_humidity
from airquality a
left join df_sensor b
on a.Month=b.month and a.Day = b.day
")

# Step 3 建置多元回歸模型
lmTrain <- lm(formula = Ozone ~ Solar_R+Wind+avg_temperature+avg_humidity, 
                  data = subset(df_allitems, complete.cases(df_allitems))) #排除null

# 模型摘要
summary(lmTrain ) 

# Step 4 預測明日臭氧濃度
New_data <- data.frame(Solar_R =200, Wind=12, avg_temperature=32.1, avg_humidity =62.7)
predicted <- predict(lmTrain , newdata = New_data)
predicted/1000 

# 結束連線
dbDisconnect(conn)

