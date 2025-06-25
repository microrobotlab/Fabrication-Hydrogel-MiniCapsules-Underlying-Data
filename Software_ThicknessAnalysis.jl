
## Include functions for Thickness Analysis
include("Functions_ThicknessAnalysis.jl");

## Read the data file and save it to a dataframe
path_to_file = "data.csv";
df = CSV.read(path_to_file, DataFrame, types=[String,Float64,Float64,Float64]);

## Add the 'linearized' thickness to the dataframe
df[!,:Ym] = linearize.(df[!,:h_mis],df[!,:Rcore]);   

## Fit of the linearized thickness to the [CaCl2]
α, R² = slopefit(df[!,:CaCl2],df[!,:Ym]);


## LinearFit plot
P_LinFit = scatter(df[!,:CaCl2],df[!,:Ym], label="linearized data",legend=:bottomright,framestyle=:box);
plot!(df[!,:CaCl2],α*df[!,:CaCl2], label="linear fit, R² = $(round(R², digits=2))");
xlabel!("[CaCl₂] (mM)");
ylabel!(L"\left(h/R_c+1\right)^3-1")
display(P_LinFit)

## Extimation of shell thickness from [CaCl2] and Rcore
df[!,:h_CaCl2] = expected_h.([α],df[!,:Rcore],df[!,:CaCl2]);

## NONLinearPlot
P_NLPlot = scatter(df[!,:CaCl2],df[!,:h_mis], label="measured",legend=:bottomright,framestyle=:box, linewidth=10);
scatter!(df[!,:CaCl2],df[!,:h_CaCl2], shape=:xcross, label="predicted");
xlabel!("[CaCl₂] (mM)");
ylabel!("Shell thickness, "*L"h"*" (μm)")
display(P_NLPlot)

## Get names of images to be analysed
imgDir = "images\\";
imgNames = (df[!,:NAME]);

## Analyse images and save results in dataframe
results = color_means.(imgDir.*df[!,:NAME].*".jpg");
color_diff_names = ("R","Rbg","RB");
for i in eachindex(color_diff_names)
    df[!,color_diff_names[i]*"Mean"] = [result[3][i] for result in results];
end

## Show 3 selected images
selected = [7,18,38];
sel_img = [results[i][1] for i in selected];
sel_img_filt = [results[i][2] for i in selected];

mosaic(sel_img...,sel_img_filt...; fillvalue=1, rowmajor=true, npad=50, nrow=2)


## Plot color differences means of analysed images
P_ImgPlt = scatter(df[!,:CaCl2],df[!,:RMean],grid=nothing, label="Red component",legend=:bottomright,framestyle=:box,left_margin = 5mm, color=2); 
scatter!(df[!,:CaCl2],df[!,:RbgMean], label="Red - background", color=3);
scatter!(df[!,:CaCl2],df[!,:RBMean], label="Red - Blue", color=1); 
xlabel!("[CaCl₂] (mM)");
ylabel!("Color Intensity (a.u.)")
display(P_ImgPlt)

## Means of Means
# Group dataframe by values in categorical column
gdf = groupby(df,:CaCl2,sort=true);
# Create DF for Means
MeanDF=DataFrame(CaCl2=sort(unique(df[!,:CaCl2])));
MeanDF[!,:Rcore] = mean.([gdfi[!,:Rcore] for gdfi in gdf]);
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
ylabel!(L"R$-$B color intensity (a.u.)")
display(P_RBL)

## Fit R-B values to measured thicknesses
lfit, lfit_R² = linearfit(Float64.(df[!,:RBMean]),df[!,:h_mis])
df[!,:h_RB] = lfit.(df[!,:RBMean]);
MeanDF[!,:h_RB] = lfit.(MeanDF[!,:RBMeans_mean]);

## Plot values and fitting results
P_ColThick = scatter(df[!,:RBMean],df[!,:h_mis],marker=true,label="data",legend=:topleft,grid=nothing,framestyle=:box,left_margin = 5mm); 
plot!(df[!,:RBMean],df[!,:h_RB], label="Linear fit, R²="*string(round(lfit_R², digits=2)));
scatter!(df[!,:RBMean],df[!,:h_RB],label=L"h_\textrm{R-B}",marker=:cross,color=2);
xlabel!(L"Color Intensity R$-$B (a.u.)");
ylabel!(L"Shell thickness, $h$ (μm)")
display(P_ColThick)

## Comparison between two extimations
P_TwoExt = scatter(df[!,:CaCl2],norm_h_Rc.(df[!,:h_mis],df[!,:Rcore]),color=1,label=L"h_\textrm{meas}/R_c",legend=:bottomright,grid=nothing,framestyle=:box,left_margin = 5mm);
plot!(MeanDF[!,:CaCl2],norm_h_Rc.(MeanDF[!,:h_CaCl2],MeanDF[!,:Rcore]),label=L"h_\textrm{CaCl_2}/R_c",color=3);
plot!(MeanDF[!,:CaCl2],norm_h_Rc.(MeanDF[!,:h_RB],MeanDF[!,:Rcore]),marker=:cross,linestyle=:dot,label=L"h_\textrm{R-B}/R_c",color=2);
ylims!(0,0.8);
xlabel!("[CaCl₂] (mM)");
ylabel!(L"h/R_c")
display(P_TwoExt)