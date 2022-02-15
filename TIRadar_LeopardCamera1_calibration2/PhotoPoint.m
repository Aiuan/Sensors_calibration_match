%% find corner reflector in pixel coordinate
clear all;  close all; clc;

image_folder="./data/LeopardCamera1_undistort_cut/";
image_list = getImageListIncludeNotFound(image_folder);

for i=1:length(image_list) 
    image_path = image_list(i).path;
    image=imread(image_path);  
    imshow(image)%��ʾ��ͼ
    title(image_path);
    set(gcf,'outerposition',get(0,'screensize'));%ʹ��ͼ��ʾ��󻯣�����ȡ��
    [data(i,4),data(i,5)] = ginput
end

save imagePoints data
