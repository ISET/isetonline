# need to have pip install fiftyone
# # and pip install torch torchvision if you want to do detection
# 
import fiftyone as fo
import torch 
import torchvision


# Read one of our COCO datasets into Voxel 51

# from our first command line test
# coco_dataset_2 = fo.Dataset.from_dir(dataset_dir=dataset_dir, 
# dataset_type=fo.types.COCODetectionDataset, name="Night_3g",)

# start with our first night time dataset (007 also exists)
dataset_dir = 'c:/iset/isetonline/local/nighttime_003/'
dataset_dir_yolo = 'c:/iset/isetonline/local/nighttime_003_yolo/'

night_dataset_2 = fo.Dataset.from_dir(dataset_dir=dataset_dir,
    dataset_type=fo.types.COCODetectionDataset)

fo.Dataset.export(night_dataset_2,dataset_dir_yolo, dataset_type=
    fo.types.YOLOv4Dataset)

# Run the model on GPU if it is available
device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")

# Load a pre-trained Faster R-CNN model
model = torchvision.models.detection.fasterrcnn_resnet50_fpn(pretrained=True)
model.to(device)
model.eval()

print("Model ready")

session = fo.launch_app(night_dataset_2, port=5052)

