data <- read.csv("data/Zimbabwe1.csv",header = T,sep = ";")
# colnames(data)
# head(data)
pheno<- data[, c(4, 7, 16,21,25,27,38,41,46,63,64,65,66,68)] 
table(pheno$LOCATION_NAME)
colnames(pheno)
pheno$geno <- gsub(" ", "_",pheno$Crop_Variety)
pheno$geno <- factor(pheno$geno)
# unique(pheno$IRRIGATION)
levels(pheno$geno) <- paste("G", 1:length(levels(pheno$geno)), sep = "_")
# table(pheno$Crop_Variety)
# table(pheno$geno)

pheno[which(pheno$HARV_DATE==""),"LOCATION_NAME"]

pheno$DTH <- as.Date(as.character(pheno$HARV_DATE), format="%m/%d/%Y")-
                  as.Date(as.character(pheno$PLANT_DATE), format="%m/%d/%Y")-5
# dim(pheno)
# colnames(pheno)
# head(pheno)
# str(pheno)
pheno$GRAIN_YLD_13PCT <-  gsub(",", ".", pheno$GRAIN_YLD_13PCT)
trial <-  gsub("_.*", "", pheno$LOCATION_NAME)
pheno$trial <- paste0(trial,"_", pheno$CROP_SEASON)
unique(pheno$TRIAL_NAME) # 41 trials
unique(pheno$LOCATION_NAME) # 14 Locations
unique(pheno$CROP_SEASON) # 6 years
length(unique(pheno$Crop_Variety)) #98 genotypes
# head(pheno)
pheno <- pheno |> rename("Plant Height"=8, "Grain Yield"=9, "Plant lodging"=7, "rep"=4,"env"=17)

traits <- c(colnames(pheno)[c(7,8,9)])
traits

factors <- c(colnames(pheno)[c(1,2,3,4,5,6,14,15,16,17)])
factors

pheno[, traits] <- lapply(pheno[, traits], as.numeric)
table(pheno$`Plant lodging`)
hist(pheno$`Grain Yield`)
table(pheno$`Plant lodging`)

pheno[, factors] <- lapply(pheno[, factors], as.factor)


diagnostic = do.call(rbind, lapply(stmt, function(x){
  aa = as.data.frame(x$summary) |> rownames_to_column("trait")
  aa
})) |> rownames_to_column("env") |> 
  mutate_at("env", str_replace, "\\..*", "") |> 
  dplyr::select(env, trait, geno) |> 
  separate(geno, into = c("genovar", "sig"), sep = " ")

# diagnostic
# dim(pheno)
# dim(pheno_filt)
# unique(pheno_filt$trial)
# levels(pheno_filt$trial)


# inpheno# install.packages("ProbBreed")
# head(pheno_filt)

i=traits[3]

library(asreml)
# Getting the path of your current open file
# current_path = rstudioapi::getActiveDocumentContext()$path 
# setwd(dirname(current_path ))
# print( getwd() )
# head(pheno)

traits
stmt = list()
j="Banket_2018" 
#j="2021NAC_ST01"
i="Plant lodging"
unique(pheno$env)
library(asreml)

summar.mat = matrix(nrow = length(traits), ncol = 4, 
                    dimnames = list(traits, 
                                    c("geno","error","H2", "CV")))




Blues=list()
for (i in traits) {
  message(paste("Analysis to", i))
  # print(paste("Analysis to", i)) 
  # cat("====> Trait:", i, fill = TRUE)
  x <- droplevels(pheno[
    which(pheno$env %in% diagnostic[which(diagnostic$trait == i &
                                              diagnostic$sig == "*"), "env"]), ])
  
  

  
  data.list = split(pheno, f = pheno$trial)
  
  
  
  for (j in names(data.list)) {
    
    
    

      message("====> Env:", j)
      
      if(all(is.na(x[,i]))) next
      
      model.r = asreml(fixed = x[,i] ~ rep, 
                       random = ~ geno,maxit = 50,
                       data = x, na.action = na.method(x = "include", y = "include"))
      
      
      
      # colocar nugget and spline
      model.f = asreml(fixed = x[,i] ~ rep+geno, 
                       maxit = 50,
                       residual = ~units,
                       data = x, na.action = na.method(x = "include", y = "include"))
      
      if(!model.r$converge) next
      
      if(any(na.exclude(model.r$vparameters.pc > 1))) model.r = update.asreml(model.r)
      # varcomp = summary(modelhvan)$varcomp
      varcomp = summary(model.r)$varcomp
      varcomp.df = data.frame(
        effect = c('genotypic', "residual"),
        component = c(round(
          varcomp[grep('geno', rownames(varcomp)),1],4),
          round(varcomp[grep('!R', rownames(varcomp)),1],4))
      )
      # if(!modelad$converge) next
      # 
      # if(any(na.exclude(modelad$vparameters.pc > 1))) modelad = up.mod(modelad)
      # 
      if(!model.f$converge) next
      
      if(any(na.exclude(model.f$vparameters.pc > 1))) model = up.mod(model.f)
      
      
      pred = predict(model.r, classify = "geno", sed = TRUE)
      pred$sed= pred$sed[-which(pred$pvals$status=="Aliased"),-which(pred$pvals$status=="Aliased")]
      MVdelta = mean((pred$sed^2)[upper.tri(pred$sed^2,diag = F)])
      H2 = 1-(MVdelta/(2*varcomp[varcomp$effect == "genotypic","component"]))
      h2 = vpredict(model.r, h2~(V1)/(V1+V2))
      
      
      
      #h2ad = vpredict(modelad, h2~(V3)/(V3+V4))
      
      CV = sqrt(varcomp[grep("r", rownames(varcomp)),"component"])/
        mean(x[,i], na.rm = TRUE)*100
      
      summar.mat[i,] = c(varcomp$signi2[1], round(varcomp$component[2],4), 
                         round(h2$Estimate,4), round(CV,4))
      
      
      pred=predict(model.f, classify = "geno", sed = T)
      
      
      # pred$vcov= pred$vcov[-which(pred$pvals$status=="Aliased"),-which(pred$pvals$status=="Aliased")]
      # pred$pvals= pred$pvals[-which(pred$pvals$status=="Aliased"),]
      # 
      # pred$pvals$w=diag(solve(pred$vcov))
      pred=pred$pvals
      
      vc.env[[i]] = varcomp.df
      
      Blue.env[[i]] = pred
    }
    stmt[[j]] = list(Blues = Blue.env,summary = summar.mat,vc=vc.env)
    
    rm(summar.mat,GEBV.env, varcomp, lrtest, model, 
       h2, CV, x, H.inv.env)
  }
  
}

stvc=lapply(Blups, function(x){
  do.call(rbind,x)
})
str(Blups)
str(Blups)
str(stvc)
