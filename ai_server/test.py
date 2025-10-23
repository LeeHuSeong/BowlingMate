from tensorflow.keras.models import load_model

pitch_types = ["twohand", "cranker", "stroker", "thumbless"]

for p in pitch_types:
    model = load_model(f"model/lstm_{p}.h5")
    print(f"{p}: input_shape = {model.input_shape}")