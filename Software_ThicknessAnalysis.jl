
## Include functions for Thickness Analysis
include("Functions_ThicknessAnalysis.jl");

## Read the data file and save it to a dataframe
path_to_file = joinpath("data","microscopy_measurements.csv");
df = CSV.read(path_to_file, DataFrame, types=[String,Float64,Float64,Float64]);
h_RCore = histogram(df[!,:Rcore], bins=900:50:1600, xlabel="Core radius (μm)", ylabel="Counts", framestyle=:box, legend=false, xlims=(0,2000));
display(h_RCore);
savefig(h_RCore, joinpath("results","RcoreHistogram.svg"));
## Calculate overall PDI as variance/mean²
pdi(mean::Float64, std::Float64) = std^2/mean^2;
pdi(x::AbstractVector) = pdi(mean(x),std(x));
PDI = pdi(df[!,:Rcore]);
PDI < 0.1 ? println("Cores are monodisperse: PDI = ", PDI) :
    println("Cores are not monodisperse: PDI = ", PDI);

## Add the 'linearized' thickness to the dataframe
df[!,:Ym] = linearize.(df[!,:h_mis],df[!,:Rcore]);   

## Fit of the linearized thickness to the [CaCl2]
α, R² = slopefit(df[!,:CaCl2],df[!,:Ym]);

## Output folder
output_folder = "results";
if !isdir(output_folder)
    mkpath(output_folder);
end

## LinearFit plot
P_LinFit = scatter(df[!,:CaCl2],df[!,:Ym], label="linearized data",legend=:bottomright,framestyle=:box);
plot!(df[!,:CaCl2],α*df[!,:CaCl2], label="linear fit, R² = $(round(R², digits=2))");
xlabel!("[CaCl₂] (mM)");
ylabel!(L"\left(h/R_c+1\right)^3-1");
display(P_LinFit)
savefig(P_LinFit, joinpath(output_folder,"LinearFitPlot.svg"));

## Extimation of shell thickness from [CaCl2] and Rcore
df[!,:h_CaCl2] = expected_h.([α],df[!,:Rcore],df[!,:CaCl2]);

## NONLinearPlot
P_NLPlot = scatter(df[!,:CaCl2],df[!,:h_mis], label="measured",legend=:bottomright,framestyle=:box, linewidth=10);
scatter!(df[!,:CaCl2],df[!,:h_CaCl2], shape=:xcross, label="predicted");
xlabel!("[CaCl₂] (mM)");
ylabel!("Shell thickness, "*L"h"*" (μm)");
display(P_NLPlot)
savefig(P_NLPlot, joinpath(output_folder,"NonLinearPlot.svg"));

## Get names of images to be analysed
imgDir = "images";
imgNames = (df[!,:NAME]);

## Analyse images and save results in dataframe
results = color_means.(joinpath.(Ref(imgDir),df[!,:NAME].*".jpg"));
color_diff_names = ("R","Rbg","RB");
for i in eachindex(color_diff_names)
    df[!,color_diff_names[i]*"Mean"] = [result[3][i] for result in results];
end

## Show 3 selected images
selected = [7,18,38];
sel_img = [results[i][1] for i in selected];
sel_img_filt = [results[i][2] for i in selected];

SelImgs = mosaic(sel_img...,sel_img_filt...; fillvalue=1, rowmajor=true, npad=50, nrow=2)
save(joinpath(output_folder, "SelectedImages.png"), SelImgs);


## Plot color differences means of analysed images
P_ImgPlt = scatter(df[!,:CaCl2],df[!,:RMean],grid=nothing, label="Red component",legend=:bottomright,framestyle=:box,left_margin = 5mm, color=2); 
scatter!(df[!,:CaCl2],df[!,:RbgMean], label="Red - background", color=3);
scatter!(df[!,:CaCl2],df[!,:RBMean], label="Red - Blue", color=1); 
xlabel!("[CaCl₂] (mM)");
ylabel!("Color Intensity (a.u.)")
display(P_ImgPlt)
savefig(P_ImgPlt, joinpath(output_folder,"ColorMeansPlot.svg"));

## Means of Means
# Group dataframe by values in categorical column
gdf = groupby(df,:CaCl2,sort=true);
# Create DF for Means
MeanDF=DataFrame(CaCl2=sort(unique(df[!,:CaCl2])));
MeanDF[!,:Rcore] = mean.([gdfi[!,:Rcore] for gdfi in gdf]);
# Calculate PDI as variance/mean²
MeanDF[!,:PDI_RCore] = pdi.([gdfi[!,:Rcore] for gdfi in gdf]);
for r in eachrow(MeanDF)
    r.PDI_RCore < 0.1 ? println("Cores for [CaCl₂] = $(r.CaCl2) mM are monodisperse: PDI = $(r.PDI_RCore)") :
    println("Cores for [CaCl₂] = $(r.CaCl2) mM are not monodisperse: PDI = $(r.PDI_RCore)");
end
# Calculate expected shell thickness from [CaCl2] and Rcore
MeanDF[!,:h_CaCl2] = expected_h.(α,MeanDF[!,:Rcore],MeanDF[!,:CaCl2]);
# Calculate means and standard deviations
functions = (mean,std);
for cd_name in color_diff_names
    for f in functions
        MeanDF[!,cd_name.*"Means_".*string(f)] = f.([gdfi[!,cd_name.*"Mean"] for gdfi in gdf]);
    end
end

## Plot R-B Means vs expected shell thickness
P_RBL = scatter(df[!,:h_CaCl2],df[!,:RBMean],grid=nothing, label="data",legend=:bottomright,framestyle=:box,left_margin = 5mm);
plot!(MeanDF[!,:h_CaCl2],MeanDF[!,:RBMeans_mean],marker=true,linestyle=:dot,yerror=MeanDF[!,:RBMeans_std], label="μ ± σ");
xlabel!(L"Theoretical shell thickness, $h_\textrm{CaCl_2}$ (μm)");
ylabel!(L"R$-$B color intensity (a.u.)");
display(P_RBL)
savefig(P_RBL, joinpath(output_folder,"RBMeansPlot.svg"));

## Fit R-B values to measured thicknesses
lfit, lfit_R² = linearfit(Float64.(df[!,:RBMean]),df[!,:h_mis])
df[!,:h_RB] = lfit.(df[!,:RBMean]);
MeanDF[!,:h_RB] = lfit.(MeanDF[!,:RBMeans_mean]);

## Plot values and fitting results
P_ColThick = scatter(df[!,:RBMean],df[!,:h_mis],marker=true,label="data",legend=:topleft,grid=nothing,framestyle=:box,left_margin = 5mm); 
plot!(df[!,:RBMean],df[!,:h_RB], label="Linear fit, R²="*string(round(lfit_R², digits=2)));
scatter!(df[!,:RBMean],df[!,:h_RB],label=L"h_\textrm{R-B}",marker=:cross,color=2);
xlabel!(L"Color Intensity R$-$B (a.u.)");
ylabel!(L"Shell thickness, $h$ (μm)");
display(P_ColThick)
savefig(P_ColThick, joinpath(output_folder,"ColorThicknessPlot.svg"));

## Comparison between two estimations
P_TwoEst = scatter(df[!,:CaCl2],norm_h_Rc.(df[!,:h_mis],df[!,:Rcore]),color=1,label=L"h_\textrm{meas}/R_c",legend=:bottomright,grid=nothing,framestyle=:box,left_margin = 5mm);
plot!(MeanDF[!,:CaCl2],norm_h_Rc.(MeanDF[!,:h_CaCl2],MeanDF[!,:Rcore]),label=L"h_\textrm{CaCl_2}/R_c",color=3);
plot!(MeanDF[!,:CaCl2],norm_h_Rc.(MeanDF[!,:h_RB],MeanDF[!,:Rcore]),marker=:cross,linestyle=:dot,label=L"h_\textrm{R-B}/R_c",color=2);
ylims!(0,0.8);
xlabel!("[CaCl₂] (mM)");
ylabel!(L"h/R_c");
display(P_TwoEst)
savefig(P_TwoEst, joinpath(output_folder,"TwoEstimationsPlot.svg"));

## Save the dataframe with results
CSV.write(joinpath(output_folder,"microscopy_measurements_results.csv"), df);
CSV.write(joinpath(output_folder,"microscopy_measurements_means.csv"), MeanDF);