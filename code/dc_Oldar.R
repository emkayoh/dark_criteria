# Oldar 
# Takes a findParameters... object 
# and applies a parameter scan to tau and alpha 

# Get some data 
reye <- '/Users/mqbxgjk2/Dropbox/Mumac_/Data_Room/05_Intellectual_Property/5.5_Research/Stimulus_aperture_size/v_00141_Standard_R_m2.txt'
leye <- '/Users/mqbxgjk2/Dropbox/Mumac_/Data_Room/05_Intellectual_Property/5.5_Research/Stimulus_aperture_size/v_00142_Standard_L_m2.txt'
rdat <- read.table(reye, sep =',', header= TRUE)
ldat <- read.table(leye, sep =',', header= TRUE)

rtime <- as.numeric(rdat[,1])/60 # convert to minutes
rthrs <- as.numeric(rdat[,2])/-10 # convert to log units attenuation

ltime <- as.numeric(ldat[, 1])/60
lthrs <- as.numeric(ldat[, 2])/-10

# generate an 'obj'
source('~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_gradient_Descent_Functions.R')
source('~/Dropbox/Mumac_/CODE_1/dark_criteria/code/dc_Huber_loss.R')

a <- c(-2, 2, 2, -0.2, 4)

x <- ltime
y <- lthrs

x <- rtime
y <- rthrs

obj <- findParametersGDPlain(a, P5c, x, y, inv = TRUE)
 

oldar <- function(obj, x, y) {
	# scan alpha using linear scale 
	params <- obj$param
	tmp <- Inf 
	alp <- seq(from = 0.5, to = max(x), length.out = 10) 
	for(ii in alp){ 
		params[5] <- ii 
		# should be Huber loss function 
		out <- findParametersGDPlainHuber(params,P5c, x, y, 1) 
		if(out$noise <= tmp) { 
			result <- out 
			tmp <- out$noise
			} 
		} 
	# scan tau using log scale 
	params <- result$param
	tmp <- Inf 
	tau <- 10^seq(from = log10(0.01), to = log10(2), length.out = 10) 
	for(ii in tau) { 
		params[3] <- ii 
		out <- findParametersGDPlainHuber(params,P5c, x, y, 1) 
		if(out$noise <= tmp) { 
			result <- out 
			tmp <- out$noise
			}
		}
	result
	}


oldar(obj, x,y)