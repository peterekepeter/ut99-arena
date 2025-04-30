
# regenerates static arena profiles
for i in range(0,100):
    path = f'FFNArena/Classes/Profiles/Profile{i}.uc'
    with open(path, 'w') as f:
        f.write(f'class Profile{i} extends FFNArenaBase;\n')