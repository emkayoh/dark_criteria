oldar <- function(obj, x, y) {
	# scan alpha using linear scale 
	params <- obj$param
	tmp <- Inf
	alp <- seq(from = 0.5, to = max(x), length.out = 10)
	for (ii in alp) {
		params[5] <- ii
		# should be Huber loss function 
		out <- fitP5cPseudoHuber(params, x, y)
		if (out$noise <= tmp) {
			result <- out
			tmp <- out$noise
		}
	}
	# scan tau using log scale 
	params <- result$param
	tmp <- Inf
	tau <- 10^seq(from = log10(0.01), to = log10(2), length.out = 10)
	for (ii in tau) {
		params[3] <- ii
		out <- fitP5cPseudoHuber(params, x, y)
		if (out$noise <= tmp) {
			result <- out
			tmp <- out$noise
		}
	}
	result
}


# oldar(obj, x,y)