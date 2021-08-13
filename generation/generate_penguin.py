from PIL import Image
import csv
import time
import os
from multiprocessing import Pool

override = True
asset_folder = "assets"
dna_file = "dna.csv"
output_folder = "output"

def generate_img(params):
    try:
        serial_no, traits = params
        if not override and f'{serial_no}.png' in existing_images:
            print(f"Skipping image #{serial_no}")
            return
        all_assets = [Image.open(f'{asset_folder}/{trait}.png') for trait in traits]
        base_image = all_assets[0]
        for img in all_assets[1:]:
            base_image.paste(img, (0, 0), img)

            base_image.save(f'{output_folder}/{serial_no}.png', 'PNG')
            print(f"Generated image #{serial_no}")
    except Exception as ex:
        print(f"Failed for {serial_no}, with exception: {ex}")


dnas = []
with open(dna_file, mode='r') as csv_file:
    csv_reader = csv.DictReader(csv_file)
    for row in csv_reader:
        dnas.append(row)

columns = list(dnas[0].keys())
all_params = []

rootdir = os.getcwd()
existing_images = []
for subdir, dirs, files in os.walk(rootdir):
    for file in files:
        if output_folder in subdir and file.endswith(".png"):
            existing_images.append(file)

for dna in dnas:
    traits = [f'{key}/{dna[key]}' for key in columns if key not in set(['serial', 'dna']) and dna[key]!= 'NONE']

    trait_vals = [t.split('/')[-1] for t in traits]
    all_params.append([dna['serial'], traits])

if __name__ == "__main__":
    pool = Pool()
    tic = time.perf_counter()
    pool.map(generate_img, all_params)
    pool.close()
    toc = time.perf_counter()
    print(f"Total time taken to process {len(dnas)} dnas is {toc - tic:0.4f} seconds")
