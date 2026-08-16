append_result_row <- function(result_row, file) {

    stopifnot(
        nrow(result_row) == 1L
    )

    new_file <-
        !file.exists(file) ||
        file.info(file)$size == 0

    write.table(
        result_row,
        file = file,
        sep = ",",
        row.names = FALSE,
        col.names = new_file,
        append = !new_file,
        quote = TRUE,
        na = "NA",
        qmethod = "double"
    )
}