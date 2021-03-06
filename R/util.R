## generic utilities
## Karl W Broman

# grab argument from a list
#
# for example:
#   grabarg(list(method="argmax", map.function="c-f"), "method", "imp")
grabarg <-
function(arguments, argname, default)
    ifelse(argname %in% names(arguments), arguments[[argname]], default)


# return selected phenotype columns as a character vector
getPhename <-
function(cross, pheno.col)
{
    if(is.character(pheno.col)) return(pheno.col)
    names(cross$pheno)[pheno.col]
}

# turn a selection of matrix columns into a numeric vector
selectMatrixColumns <-
function(matrix, cols)
{
    stopifnot(is.matrix(matrix))

    origcols <- cols

    if(is.character(cols)) {
        cols <- match(cols, colnames(matrix))
        if(any(is.na(cols)))
            stop("Unmatched columns: ", paste(origcols[is.na(cols)], collapse=" "))
    }

    (1:ncol(matrix))[cols]
}

# extract phenotypes
extractPheno <-
function(cross, pheno.col)
{
    if(is.character(pheno.col)) {
        pheindex <- qtl::find.pheno(cross, pheno.col)
        if(any(is.na(pheindex)))
            stop("Some phenotypes not found: ",
                 paste(pheno.col[is.na(pheindex)], collapse=" "))
        pheno.col <- pheindex
    }
    if(is.matrix(pheno.col) && nrow(pheno.col) == qtl::nind(cross))
        return(pheno.col) # treat as phenotype matrix
    if(is.numeric(pheno.col) && length(pheno.col) == qtl::nind(cross))
        return(cbind("phenotype"=pheno.col))

    if(is.numeric(pheno.col)) { # look for problem indices
        if(any(pheno.col == 0))
            stop("Cannot have pheno.col == 0")
        if(any(pheno.col < 0) && !all(pheno.col < 0))
            stop("Cannot give a mixture of positive and negative indices")
    }

    # handle negative indices and logical values
    pheno.col <- (1:qtl::nphe(cross))[pheno.col]

    phe <- cross$pheno[,pheno.col,drop=FALSE]
    isnum <- vapply(phe, is.numeric, TRUE)
    if(!all(isnum))
        stop("Some phenotypes not numeric: ",
             paste(qtl::phenames(cross)[pheno.col[!isnum]], collapse=" "))

    as.matrix(phe)
}

# signed LOD scores
#
# If columns==1 and the first column is not "a", we don't change signs
# Otherwise, take the average across these columns to determine the sign
calcSignedLOD <-
function(scanoneOutput, effects, columns=1)
{
    stopifnot(length(effects) == nrow(scanoneOutput))
    stopifnot(all(vapply(effects, nrow, 1) == ncol(scanoneOutput)-2))

    signs <- t(vapply(effects, function(a) {
        if(length(columns)==1 & columns==1 && colnames(a)[1]!="a") return(rep(1, nrow(a)))
        (rowMeans(a[,columns,drop=FALSE], na.rm=TRUE)>=0)*2-1
    }, effects[[1]][,1]))

    scanoneOutput[,-(1:2)] <- signs * scanoneOutput[,-(1:2)]

    scanoneOutput
}

# test if a vector is a set of equally-spaced values
is_equally_spaced <-
function(vec, tol=1e-5)
{
    if(length(vec) < 2) {
        warning("vector has length < 2")
        return(FALSE)
    }

    if(!is.numeric(vec)) {
        warning("vector is not numeric")
        return(FALSE)
    }

    if(any(is.na(vec))) {
        warning("vector contains missing values")
        return(FALSE)
    }

    d <- diff(vec)
    if(!(all(d >= 0) || all(d <= 0))) {
        warning("vector is not monotonic")
        return(FALSE)
    }

    return(sd(d)/abs(median(d)) < tol) # if TRUE, looks equally spaced
}
