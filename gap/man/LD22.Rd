\name{LD22}
\alias{LD22}
\title{LD statistics for two diallelic markers}
\usage{LD22(h,n)}
\description{
LD statistics for two SNPs.

It is possible to perform permutation test of \eqn{r^2} by re-ordering the genotype through
R's sample function, obtaining the haplotype frequencies by \code{\link[gap]{gc.em}}
or \code{\link[gap]{genecounting}}, supplying the estimated haplotype frequencies to
the current function and record x2, and comparing the observed x2 and that from the
replicates.

}

\arguments{
 \item{h}{a vector of haplotype frequencies}
 \item{n}{number of haplotypes}
}

\value{
The returned value is a list containing:

\item{h}{the original haplotype frequency vector}
\item{n}{the number of haplotypes}
\item{D}{the linkage disequilibrium parameter}
\item{VarD}{the variance of D}
\item{Dmax}{the maximum of D}
\item{VarDmax}{the variance of Dmax}
\item{Dprime}{the scaled disequilibrium parameter}
\item{VarDprime}{the variance of Dprime}
\item{x2}{the Chi-squared statistic}
\item{lor}{the log(OR) statistic}
\item{vlor}{the var[log(OR)] statistic}
}

\section{References}{
Zabetian CP, Buxbaum SG, Elston RC, Kohnke MD, Anderson GM, Gelernter J, Cubells JF.
The structure of linkage disequilibrium at the DBH locus strongly influences the 
magnitude of association between diallelic markers and plasma dopamine beta-hydroxylase activity
Am J Hum Genet 72: 1389-1400 

Zapata C, Alvarez G, Carollo C (1997) Approximate variance of the standardized
measure of gametic disequilibrium D'. Am. J. Hum. Genet. 61:771-774
}

\seealso{
\code{\link[gap]{LDkl}}
}
\examples{
\dontrun{
h <- c(0.442356,0.291532,0.245794,0.020319)
n <- 481*2
t <- LD22(h,n)
t
}
}
\author{Jing Hua Zhao}
\note{extracted from 2ld.c}
\keyword{models}
