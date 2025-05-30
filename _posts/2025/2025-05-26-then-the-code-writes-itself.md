---
layout: post
title: Then the code writes itself
tags: coding
image: "/assets/implement.png"
---

| ![implement](/assets/implement.png) |
|:--:|
| _Talking to Claude Code_ |

I wrote [MCP In the Shell](/mcp-in-the-shell) with Claude Code. Basically all the tests and functions inside that Github repo, Claude wrote for me. But how did it know what code to write? What tests to specify? I 'talked' to it by typing stuff in, but what does that look like? I'd like to show you without having you parse through millions of tokens of conversation.

![owl](/assets/claude-code-owl.png) 

If you've lived your life in the mid-2010s on Reddit like me, you'll remember the meme. The abstraction here is to go from a rough sketch to a final product in steps. At first, it may look crude and nothing like what you end up with, but Claude can help you coagulate your thoughts along the way.

First I start with a thinking session outside - IRL outside, where I touch grass. This is when I gather inspiration about what I want the inputs and outputs to be. If you don't know what those are, no computer can help you. The input could be a user interaction, a structured data format, or natural language. The output can be anything within the laws of physics (it's usually some kind of data, though). I also put in the context where the application will live. 

```
|   i want you to pay close attention to mcp_round_trip.py - I am looking to extract a reusable component called mcp-ghost where instead of a cli interface,   │
│   it takes inputs from python directly. This component should be copy-pastable with the dependencies inside mcp_round_trip only, with the exception of       │
│   mcp-cli not being a dependency. functions imported from mcp-cli should be rewritten. There are several parameters into mcp-ghost: the mcp server config    │
│   json, a natural language system prompt that provides additional context for the llm on how to use the tools, provider, api key for the provider, and user  │
│   prompt. mcp-ghost should output the list of tool calls that it made, a summary of the output from the tool calls, and error messages if any. mcp-ghost     │
│   will be used in the context of a larger architecture where the user input will be a combination of a conversation between a human user and a               │
│   prompt=builder. the role of the prompt builder is to produce a complete structured input so that mcp-ghost can one-shot the tool calls with high           │
│   probability. the prompt builder will also ensure a basic level of security where it only allows a limited set of actions to be passed along to mcp-ghost.  │
│   As a mcp client, mcp-ghost should be able to handle stdio calls in full confidence, with security concerns limited to which mcp servers it has been        │
│   provided. I'd like you to write a markdown of some of these requirements for my review, so that it's easy for you to write tests for.
```

Next up is the requirements doc. I only write like 10-20 lines of README before I get into this step. You can see my example in the Github Repo: [REQUIREMENTS.md](https://github.com/kimjune01/mcp-ghost/blob/main/REQUIREMENTS.md). Here is a chance to intercept mistakes it's about to make before it goes off on a big tangent. I required that it make use of snapshot testing instead of mocks. In a later step, I just referred to the requirements doc to Claude, and it fixed the mistake by itself.

Once I'm confident that the requirements are aligned with what I'm looking to achieve, I ask it to write some basic failing tests, a practice from TDD. I also ask it to write interfaces with stub implementations, so that the tests can fail its expectations. This is when Claude sets up the testing suite. Without testing, code that Claude writes is just a wish upon a star. 

Claude doesn't know exactly what you mean by tests, so you'll need to specify between unit tests, module tests, integration tests, and the level of sophistication you require. I always write the minimal number of tests to get the code started. Testing edge cases and input validations can wait until later.

![golden-test-viewer](/assets/golden-test-viewer.png)

I then ask it to provide a GUI to make it easier for me to be in the loop. Here is my last chance to catch mistakes before it works its magic. If I'm happy with the tests, I simply ask it to `implement`. Actually, I found that I need to ask it to implement multiple times because it likes to take frequent breaks between passing tests incrementally.
