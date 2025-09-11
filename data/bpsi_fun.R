## Function prob_sup
##
##' @title Bayesian Probabilistic Selection Index (BPSI)
##'
##' @description
##' This function estimates the genotipic merit for multiple traits using the 
##' probabilities of superior performance across environments.
##'
##' @param modlist A list of object of class `probsup`, obtained from the [ProbBreed::prob_sup] function
##' @param increase Logical vector of amount of traits used in the same order of modlist.`TRUE` (default) if the selection is for increasing the trait value, `FALSE` otherwise.
##' @param omega A numeric representing the weigth of each trait, the default is 1, the trait with more 
##' economic interest should be greater.
##' @param int A numeric representing the selection intensity
##' (between 0 and 1)
##'##' @param save.df Logical. Should the data frames be saved in the work directory?
##' `TRUE` for saving, `FALSE` (default) otherwise.
##' @param verbose A logical value. If `TRUE`, the function will indicate the
##' completed steps. Defaults to `FALSE`.
##'
##' @return The function returns an object of class `BPSI`, which contains two lists,
##' one with the `BPSI`- Bayesian Probabilistic Selection Index, and another with the original `data`-  
##' with across-environments probabilities for each trait.
##' 
##'
##' 
##'
##' @details
##' Probabilities provide the risk of recommending a selection candidate for a target
##' population of environments or for a specific environment. `prob_sup`
##' computes the probabilities of superior performance and the probabilities of superior stability:
##'
##' \itemize{\item Probability of superior performance}
##'
##' 
##' \deqn{BPSI_{i}=\sum_{m=1}^t \frac{RankProSup}{\omega}}
##'
##' where \eqn{t} is the total number of traits evaluated \eqn{\left(m = 1, 2, ..., t \right)},
##' and \eqn{\omega} is the weight for each trait.
##'
##' 
##' More details about the usage of `BPSI`, as well as the other function of
##' the `ProbBreed` package can be found at \url{https://saulo-chaves.github.io/ProbBreed_site/}.
##'
##' @references
##'
##' Dias, K. O. G, Santos J. P. R., Krause, M. D., Piepho H. -P., Guimarães, L. J. M.,
##' Pastina, M. M., and Garcia, A. A. F. (2022). Leveraging probability concepts
##' for cultivar recommendation in multi-environment trials. \emph{Theoretical and
##' Applied Genetics}, 133(2):443-455. \doi{10.1007/s00122-022-04041-y}
##'
##' Shukla, G. K. (1972) Some statistical aspects of partioning genotype environmental
##' componentes of variability. \emph{Heredity}, 29:237-245. \doi{10.1038/hdy.1972.87}
##' 
##' Chaves, S. F. S., Krause, M. D., Dias, L. A. S., Garcia, A. A. F., & Dias, K. O. G. (2024).
##' ProbBreed: a novel tool for calculating the risk of cultivar recommendation in multienvironment trials.
##' G3 Genes|Genomes|Genetics, 14(3). 
##' \doi{https://doi.org/10.1093/G3JOURNAL/JKAE013}
##'
##'
##' @import ggplot2
##' @importFrom utils write.csv combn
##' @importFrom stats reshape median quantile na.exclude model.matrix aggregate
##' @importFrom rlang .data
##'
##' @seealso [ProbBreed::plot.probsup]
##'
##' @export
##'
##' @examples
##' \donttest{
##' mod = bayes_met(data = maize,
##'                 gen = "Hybrid",
##'                 loc = "Location",
##'                 repl = c("Rep","Block"),
##'                 trait = "GY",
##'                 reg = "Region",
##'                 year = NULL,
##'                 res.het = TRUE,
##'                 iter = 2000, cores = 2, chain = 4)
##'
##' outs = extr_outs(model = mod,
##'                  probs = c(0.05, 0.95),
##'                  verbose = TRUE)
##'
##' results = prob_sup(extr = outs,
##'                    int = .2,
##'                    increase = TRUE,
##'                    save.df = FALSE,
##'                    verbose = FALSE)
##'                    
##'                    
##' }
##'


BPSI = function(modlist, increase = c(TRUE,FALSE,FALSE), omega, int, save.df = FALSE, verbose = FALSE){

  stopifnot("Please, provide a valid vector of selection direction" !=is.null(increase))
  stopifnot("Please, provide names to the list of models" !=is.null(names(modlist)))
  stopifnot("Please, provide a list of objects from class probsup" =class(modlist[[1]])=="probsup")
  stopifnot("Please provide a list with same number of genotypes for all traits" = 
              all(dim(modlist[[1]]$across$perfo) == dim(modlist[[2]]$across$perfo),
                  dim(modlist[[2]]$across$perfo) == dim(modlist[[3]]$across$perfo)))
  stopifnot("Please, provide a valid selection intensity (number between 0 and 1)" = {
    is.numeric(int)
    int >= 0 & int <=1
  })
 
  
  df <- data.frame(matrix(nrow = length(modlist[[1]]$across$perfo$ID), 
                          ncol = length(modlist)))
  rownames(df) <- modlist[[1]]$across$perfo$ID
  colnames(df) <- names(modlist)
  rownames(df)=sort(row.names(df),decreasing = F)
  # Preparation
  for (traits in 1:length(modlist)) {
        tname=names(modlist[traits])
    a=modlist[[traits]]$across$perfo[order(modlist[[traits]]$across$perfo$ID,decreasing =F),]
    df[paste0(tname)]=a$prob
    rm(a)
  }
  
  if(is.null(omega)) omega=1 else omega=omega

    bpsi <- as.data.frame(apply(df, 2, function(x) {
      rank(-x, ties.method = "min", na.last = "keep")
    }))

bpsi = bpsi / omega
bpsi$bpsi=rowSums(bpsi)  
head(bpsi)

gen_sel = bpsi[order(bpsi$bpsi,decreasing = F),]

gen_i = round((length(gen_sel$bpsi) * int),0)

selected=gen_sel[1:gen_i,]

bpsi$sel=ifelse(rownames(bpsi) %in% rownames(selected) , "Selected","Not_Selected")
bpsi=bpsi[order(bpsi$bpsi,decreasing = F),]
bpsi$gen=rownames(bpsi)
if(verbose) message('-> Genotypes selected using BPSI')
attr(bpsi, "control")=int
output = list(BPSI=bpsi,df=df) 
class(output)="BPSI"

library(tidyverse)




      
      ## Save data frames in the work directory -----------------
      if(save.df){
        dir.create(path = paste0(getwd(),'/BPSI'))
        utils::write.csv(output$BPSI,
                         file = paste0(getwd(),'/BPSI/bpsi.csv'),
                         row.names = F)
        utils::write.csv(output$df,
                           file = paste0(getwd(),'/BPSI/prob_df.csv'),
                           row.names = F)
        }
      # Final output -----------
      if(verbose) message('Process completed!')
      return(output)

    
  }
  


#' Plots for the `BPSI` object
#'
#' Build plots using the outputs stored in the `BPSI` object.
#'
#'
#' @param x An object of class `BPSI`.
#' @param category A string indicating which plot to build. See options in the Details section.

#' @param ... currently not used
#' @method plot BPSI
#'
#' @details The available options are:
##' Probabilities provide the risk of recommending a selection candidate for a target
##' population of environments or for a specific environment. `prob_sup`
##' computes the probabilities of superior performance and the probabilities of superior stability:
##'
##' \itemize{\item Probability of superior performance}
##'
##' 
##' \deqn{BPSI_{i}=\sum_{m=1}^t \frac{RankProSup}{\omega}}
##'
##' where \eqn{t} is the total number of traits evaluated \eqn{\left(m = 1, 2, ..., t \right)},
##' and \eqn{\omega} is the weight for each trait.
##'
##' 
##' More details about the usage of `BPSI`, as well as the other function of
##' the `ProbBreed` package can be found at \url{https://saulo-chaves.github.io/ProbBreed_site/}.
##'
##' @references
##'
##' Dias, K. O. G, Santos J. P. R., Krause, M. D., Piepho H. -P., Guimarães, L. J. M.,
##' Pastina, M. M., and Garcia, A. A. F. (2022). Leveraging probability concepts
##' for cultivar recommendation in multi-environment trials. \emph{Theoretical and
##' Applied Genetics}, 133(2):443-455. \doi{10.1007/s00122-022-04041-y}
##'
##' Shukla, G. K. (1972) Some statistical aspects of partioning genotype environmental
##' componentes of variability. \emph{Heredity}, 29:237-245. \doi{10.1038/hdy.1972.87}
##' 
##' Chaves, S. F. S., Krause, M. D., Dias, L. A. S., Garcia, A. A. F., & Dias, K. O. G. (2024).
##' ProbBreed: a novel tool for calculating the risk of cultivar recommendation in multienvironment trials.
##' G3 Genes|Genomes|Genetics, 14(3). 
##' \doi{https://doi.org/10.1093/G3JOURNAL/JKAE013}
#'
#'
#' @seealso  [ProbBreed::prob_sup]
#'
##' @import ggplot2
##' @importFrom stats reshape na.exclude
##' @importFrom rlang .data
##'
#' @rdname plot.probsup
#' @export
#'
#' @examples
#' \donttest{
##' mod = bayes_met(data = maize,
##'                 gen = "Hybrid",
##'                 loc = "Location",
##'                 repl = c("Rep","Block"),
##'                 trait = "GY",
##'                 reg = "Region",
##'                 year = NULL,
##'                 res.het = TRUE,
##'                 iter = 2000, cores = 2, chain = 4)
##'
##' outs = extr_outs(model = mod,
##'                  probs = c(0.05, 0.95),
##'                  verbose = TRUE)
##'
##' results = prob_sup(extr = outs,
##'                    int = .2,
##'                    increase = TRUE,
##'                    save.df = FALSE,
##'                    verbose = FALSE)
##'
##' plot(results, category = "hpd")
##' plot(results, category = "perfo", level = "across")
##' plot(results, category = "perfo", level = "within")
##' plot(results, category = "stabi")
##' plot(results, category = "pair_perfo", level = "across")
##' plwithin = plot(results, category = "pair_perfo", level = "within")
##' plot(results, category = "pair_stabi")
##' plot(results, category = "joint")
#' }
#'


plot.BPSI = function(BPSI_result, ..., category = "BPSI"){

  obj = BPSI_result
  
  
  # Namespaces
  requireNamespace('ggplot2')

  stopifnot("Object is not of class 'BPSI'" = class(obj) == "BPSI")

  obj=BPSI_result[[1]]
  #control = attr(obj, "control")
  
  #ord_gen = factor(obj$across$perfo$ID, levels = obj$across$perfo$ID)
  #retrieve = function(x) do.call(rbind, strsplit(x, '@#_'))[,1]
  obj$gen=rownames(obj)
  
  
  obj <- obj |> 
    mutate(id = row_number(),
           angle = 90 - 360 * (id - 0.5) / n(),
           hjust = ifelse(angle < -90, 1, 0),
           angle = ifelse(angle < -90, angle + 180, angle))
  
  traits <- colnames(obj)[!colnames(obj) %in% c("bpsi","sel","gen", "angle", "hjust","id")]
  obja=obj
  
  library(tidyverse)
  library(ggrepel)
  library(gghighlight)
  obja=obj |> pivot_longer(paste(traits,sep = ":"),names_to = "trait",values_to = "rank")
  
  selected=obja[which(obja$sel %in% "Selected"),]
  
 
  
 
  
  # Rank plot --------------
  if(category == "Ranks"){
    
 
    # geom_bar(aes(x = as.factor(gen), y = max(rank) - rank, fill = "Selected"), 
    #          data = subset(obja, gen %in% selected$gen), 
    #          stat = "identity") +
    # geom_bar(aes(x = as.factor(gen), y = max(rank) - rank, fill = "Not_Selected"),
    #          data = subset(obja, !gen %in% selected$gen), 
    #          stat = "identity") +    
    ggplot() +
      geom_col( aes(x = gen,y = max(rank) - rank, fill=sel),data=obja)+

      # geom_hline(data = subset(obja, gen %in% selected$gen) %>% group_by(trait) %>% summarize(max_rank = max(rank)),
      #            aes(yintercept = max_rank), linetype = "dashed", color = "red", size = 0.5) +
      
      facet_wrap(~trait, scales = "free_x") +
      theme(
        axis.text.x = element_text(size = 4, angle = 90, hjust = 1, vjust = 0.5),
        panel.background = element_blank(),
        legend.position = "top",
        strip.text = element_text(size = 8,face = "bold")) +
      scale_fill_manual(
        values = c("Selected" = "blue3", "Not_Selected" = "grey"),
        breaks = c("Not_Selected", "Selected"),
        labels = c("Not selected", "Selected")
      ) +  
      labs(
        x = "Genotypes", 
        y = "Ranking of superior performance", 
        fill = expression(bold(Pr(g %in% Omega)))
      )


    
    
  }
  
  
  # BPSI plot --------------
  else if(category == "BPSI"){
    
  
    
    ggplot(obj, aes(x = as.factor(id), y = max(bpsi) - bpsi, fill = sel)) +  # Reverse values
      geom_col() +
      scale_fill_manual(values = c("Selected" = "blue3",
                                   "Not_Selected" = "grey"),
                        breaks = c("Not_Selected","Selected"),
                        labels = c("Not selected","Selected")) +
      geom_point(data = data.frame(Sel = c("Not_Selected","Selected")),
                 aes(x = 0, y = 0, color = Sel),
                 inherit.aes = FALSE, size = 4, alpha = 0) +
      scale_color_manual(values = c("Selected" = "blue3",
                                    "Not_Selected" = "grey"),
                         name = NULL,
                         guide = "none") +
      coord_polar(start = 0) +
      geom_segment(aes(x = id, xend = id, y = max(bpsi) - bpsi, yend = max(bpsi) + 5),  # Adjusted
                   color = "grey100", linewidth = 0.3) +
      geom_text(aes(x = id, y = max(bpsi) + 10,  # Keep original positioning
                    label = gen, angle = angle, hjust = hjust),
                size = 2.8) +
      theme_minimal() +
      theme(axis.text = element_blank(),
            axis.title = element_blank(),
            panel.grid = element_blank(),
            legend.position = "top") +
      labs(fill = NULL) +
      # Remove any axis labels that might show transformed values
      scale_y_continuous(labels = NULL)
    
    
    # ggplot() +
    #   geom_col(
    #     aes(y = bpsi, x = reorder(gen,bpsi), fill = gen),
    #     data = subset(obj, gen %in% selected$gen)
    #   )+geom_col(
    #     aes(y = bpsi, x = reorder(gen,bpsi)),
    #     fill = "grey",
    #     data = subset(obj, !gen %in% selected$gen)
    #   ) +geom_hline(yintercept = max(selected$bpsi))+
    #   scale_fill_manual(values = viridis::turbo(length(unique(selected$gen)))) +
    #   theme_minimal() +
    #   labs(x = "Generation", y = "BPSI", fill = "Generation") +
    #   geom_label_repel(
    #     data = subset(obj, gen %in% selected$gen),
    #     aes(x = gen, y = bpsi, label = gen),  # Specify x and y aesthetics
    #     fill = "lightblue", size = 2.25,
    #     box.padding = 0.1, max.overlaps = 20,label.padding = 0.1,
    #     label.size = 0.1,max.time = 1.0,
    #     nudge_x = 7.0,nudge_y = 7.0,force=10,force_pull = 10,max.iter = 20000
    #   ) +
    #   gghighlight(gen %in% selected$gen) +
    #   geom_hline(
    #     aes(yintercept = max(bpsi, na.rm = TRUE), linetype = "BPSI"),  # Handle NA values
    #     color = "black"
    #   ) +
    #   labs(
    #     x = "Genotypes", y = "BPSI", , linetype = "Selected"
    #   ) +guides(fill = "none")+
    #   theme(
    #     axis.text.x = element_blank(),
    #     legend.position = "top",
    #     axis.title.y = element_text(size = 12),
    #     axis.title.x = element_text(size = 12),
    #     axis.text.y = element_text(size = 12)
    #   ) +
    #   scale_y_reverse(n.breaks=10) 
    
    
    
    
    
  }

}


#' Print an object of class `BPSI`
#'
#' Print a `BPSI` object in R console
#'
#' @param x An object of class `BPSI`
#' @param ... currently not used
#' @method print BPSI
#'
#' @seealso [ProbBreed::BPSI]
#'
#' @export
#'

print.BPSI = function(BPSI_result, ...){
  obj = BPSI_result
  message("==> Considering an intensity of ", attr(obj[[1]], "control") *100,'%, here are the selected candidates:')
  obj=obj[[1]]
  obj$gen=rownames(obj)
  rownames(obj) = NULL
  print(obj)
}

