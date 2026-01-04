<img src="https://rnx.su/s/ckNQqDTNRrb9r89/download/Frame_17.png">

------------
<h3 align="center">
Create your own Mario Forever game with Thunder Engine.
</h3>

<div align="center">
Thunder Engine is a definitive open platform for Mario Forever games.<br/>
It allows you to create games with previously unseen level of flexibility and stability.
</div>

------------

<h3 align="center">
Current state: PRODUCTION READY<br/>
Required game engine:<br/>
Godot 4.4.1<br/>
</h3>

------------
<h2>How to use the Engine</h2>

<h3>Preparation</h3>

1. Get started with the [template](https://github.com/Thunder-Engine-Dev/te-template) (stable, Godot 4.4.1) to create a new repository for your game. Make sure to choose PRIVATE visibility if you don't want your game sources to be open for everyone.
- Use the [unstable template](https://github.com/Thunder-Engine-Dev/te-unstable-template) to try out the latest features of the engine.
2. Install [Git](https://git-scm.com/downloads).
3. Install [Godot Engine 4.4.1](https://godotengine.org/download/archive/4.4.1-stable/) (standard edition). If you are going to program with C#, please choose **Mono** edition.

<h3>Installation</h3>

1. Open a terminal or a command line in a directory where you want to store your project.<br/>
2. Clone your project template to your computer:

<code>git clone https://github.com/your-github-username/your-project-name --recursive</code><br/>
(Replace the github link there with your own github project repository link that you made in Preparation stage)<br/>

3. After cloning the project, navigate to it:

<code>cd your-project-name</code>

4. Update the engine:

<code>git submodule update --remote</code><br/>
- If it gives an error, then enter these commands one by one: <code>cd engine</code>, <code>git reset --hard</code>, <code>cd ..</code>

5. Import the project to Godot Engine.

<h3>Notes and Hints</h3>

- If you need to edit or add something to your project, do **not** edit the <code>engine</code> folder. Instead, duplicate the desired scenes/resources/scripts from the engine to your project repository. Everything outside of the <code>engine</code> folder is considered as your own project.

- To make a new level, add a new scene with "Level" class as the root node. All required elements for the level will be created automatically.

- To make a new map, copy the scene at "res://engine/scenes/map/template.tscn" to your project. Similarly, you can copy "complete_template.tscn".

- To replace the default save room, main menu and credits scenes, copy the corresponding template scenes to your project first (The templates already include them). To change references, open up Project Settings, turn on "Advanced Settings", go to the Application/Thunder Settings section and replace the paths to match your project.

- Please keep an eye whenever the engine receives a new update. You can press the Watch button in this repository to get notifications, or join our Discord server and follow the `#github-updates` channel. New updates provide more functions and stability. To update it in your project, see Step 4 in the Installation section of this README document. Note that any changes you make inside the `engine` folder will be reset, unless you fork it and update the fork instead. (Forks cannot be private)

- Join our [Discord Server](https://discord.gg/VwgV6GmwXv) for assistance.

------------
All of the assets and GFX are all courtesy of Nintendo. This project is free and is not created for any sort of profit. We also do not condone commercial use of our engine.
