# Collection of functions for analysis the thickness of the hydrogel microcapsules
# ===

# Import packages
# ---
# Packages for data import
using CSV
using CategoricalArrays
using DataFrames
# Packages for data analysis
using Statistics
using Images
using LinearAlgebra
using CurveFit
# Packages for data visualization
using Plots
using LaTeXStrings
using Plots.Measures

# Functions
# ---
function linearize(h,R_c)
    return (h/R_c + 1)^3 - 1
end

function slopefit(x_col,y_col)
    x, y = skipmissings(x_col,y_col) .|> collect;
    α = x \ y
    R² = r_square(y, α*x)
    return α, R²
end

function r_square(ydata,ypred)
    SSres = sum((ydata.-ypred).^2)
    SStot = sum((ydata.-mean(ydata)).^2)
    return 1 - SSres/SStot
end

expected_h(α,Rcore,c_CaCl₂) = Rcore*((α*c_CaCl₂ + 1)^(1/3)-1)

function maskImage(img);
    rat = 1/4;
    img_scaled = imresize(img,ratio=rat);
    imgRGB  = float.(channelview(img_scaled));
    imgR = @view imgRGB[1,:,:];
    imgG = @view imgRGB[2,:,:];
    imgB = @view imgRGB[3,:,:];
    
    imgRGBsm = copy(imgRGB);
    for i = 1:3
        if rat == 1/4
            mdf = 3;
            gsf = 7;
        else
            mdf = 11;
            gsf = 25;
        end
        imgRGBsm[i,:,:] = imfilter(mapwindow(median,imgRGB[i,:,:],(mdf,mdf)),Kernel.gaussian(gsf));
    end
    imgRGBsm_vec = reshape(imgRGBsm,3,:);
    R = kmeans(imgRGBsm_vec,2, init=[1,size(imgRGBsm_vec,2)÷2], display=:none);
    @assert ImageSegmentation.Clustering.nclusters(R) == 2; # verify the number of clusters
    a = ImageSegmentation.Clustering.assignments(R);
    aimg = reshape(a,axes(imgR));
    if a[1] == 1
        idx = 2;
    else
        idx = 1;
    end
    mask = aimg.== idx;
    
    labelled = label_components(mask);
    areas = component_lengths(labelled); # areas[0] is the background
    areas = areas[1:end];
    selected = findfirst(areas.==maximum(areas));
    radius = 0.25*sqrt(areas[selected])/2;
    center = round.(Int,component_centroids(labelled)[selected]);
    mask .= false;
    for i in 1:size(mask,1), j in 1:size(mask,2)
        distance = sqrt((i-center[1])^2 + (j-center[2])^2);
        if distance <= radius
            mask[i,j] = true;
        end
    end

    img_masked = colorview(RGB, imgR.*mask, imgG.*mask, imgB.*mask);
    #display(mosaicview(img,img_masked, ncol=2)); # shows selected areas for each image

    red_mean_masked = mean(imgR[mask]);
    
    rb_mean_masked = mean(imgR[mask]-imgB[mask]);

    mask_bg = labelled .== 0;
    rbg_mean_masked = mean(imgR[mask])-mean(imgR[mask_bg]);

    return img_scaled, img_masked, (red_mean_masked, rbg_mean_masked, rb_mean_masked);
end

function color_means(imgPath)
    img = load(imgPath)
    return maskImage(img)
end

norm_h_Rc(h,Rcore) = h/Rcore;

function linearfit(x_col,y_col)
    rb_mean, h = skipmissings(x_col,y_col) .|> collect;
    lfit = curve_fit(LinearFit, rb_mean, h);
    lfit_R² = r_square(h,lfit.(rb_mean));
    return lfit, lfit_R²
end