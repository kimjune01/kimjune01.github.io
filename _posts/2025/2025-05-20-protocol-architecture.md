---
layout: post
title: Protocol Architecture
tags: coding
---

I've been coding with MCP a lot recently, and I keep getting surprised at how much of what we used to hard-code can now be done with agentic tool calls. For example, with the multi-window view ([Loom demo](https://www.loom.com/share/92bad9d86de64f1e806c4a816e4f348b?sid=b511d8fa-dfb1-4bab-9232-e0a2a9b8df82)), I started the project with a narrow scope in mind: to make an executive view for restaurant evaluations. I was thiking of a three-panel view with videos, map, and menu. But as I was coding, it occurred to me that I can simply parameterize the window-making into a tool call and Claude would take care of the rest. 


### History

In a traditional MVC(Model View Controller) architecture, each user interaction is laid out individually in the controller, and views are mapped to the user mental model. In this context, model doesn't just mean a data schema; it refers to the user expectations of what happens in the system. In the classic banking example, it's about money going in and out of an account. Although in reality, modern banking is a ledger-based system on fiat. 

![mvc](/assets/mvc.png)

An application is a shippable bundle of logic that enables a user to interact with the underlying system. User stories/features are a predefined path in the graph. It was the software developer's job to faciliatate those interactions by building, testing, and shipping increments to the end user.

But what if such a path can be generated by AI?

When LLMs appeared into public consciousness, it was ridiculed for not knowing how many Rs there were in the word "Strawberry". Even though it could perform nondeterministic semantic tasks such as writing essays and poems, it wasn't able to perform deterministic quantitative tasks. It was hard to imagine letting it do anything on a user's behalf. 

Tool calling was introduced to supplement the AI so that the gap between the semantic and the quantitative can be bridged. It could call on tools, but that wasn't enough because a human had to be involved in hooking up the tools to the agents. Clever tools came along from people who were used ot ML training pipelines such as langchain and n8n. Zapier tried to fit agents into their users' workflows. Manually declaring data types from node to node made these tools clunky, used only by those who understood the concreteness of data types. 

We were stuck thinking about applications as a way to tunnel user intent from each platform to the underlying data manipulation.

![mxn](/assets/mxn.png)

Each client had to implement integrations with its tools. Then came [MCP](https://modelcontextprotocol.io/introduction). Modularity that MPC enables turns the integration effort from a `M * N` space to a `M + N` space, where M and N are AI front-ends and MCP servers. 

![mpn](/assets/mpn.png)

If any interface to an SDK or tools are available via calling via natural language, we have effectively eliminated the need for a software developer to hook up the wiring. That job is on its way out. With the Wi-Fi and bluetooth protocol, can you imagine needing a cable guy every time you wanna make an app that hooks up some static UI to a backend?

![cable-guy](/assets/cable-guy.jpg)

### Transitional Present

LLMS can't yet generate UI as good as the handcrafted ones yet. So a typical app architecture in the present still RESTs on top of APIs like this:

![api-dataflow](/assets/api-dataflow.png)

Where the client has to coordinate with the server, a schema is defined, possibly versioned. A request is made from the client requesting for a specific shape of data so that it can be presented in the UI layer. We're used to this – this works.

But as the development organization grows, and technical specializations solidify, the human coordination required becomes more work than the actual coding itself. Changes to the schema have to be coordinated between multiple release cadences.

![mcp-dataflow](/assets/mcp-dataflow.png)

But with MCP servers, the schema is no longer needed. LLMs are so good at massaging data shapes, that converting from one form to another only requires one example to be shown. Migrations are instant. Modules, isolated. Backend requests are now MCP tools. Frontend updates are now MCP tools. Human coordination be gone. As long as the data required for the job arrives, it doesn't matter if it's in a box or a basket, JSON or XML. 

With LLM performance reaching levels comparable to server uptime, The only downside is an extra bit of latency introduced by the LLM. And those things are only getting faster.

### Agentic Future

So what's different now? If we can configure the use case at runtime, capabilities only need to be engineered to enable user stories. The users write their own user stories. 

![protocol-architecture](/assets/protocol-architecture.png)

Yes, the user will need to bring more keys and secrets for the trust that the tools require. But once registered, they will be able to access all the world's digital offerings. Email, calendar, uber, doordash, airbnb, taskrabbit, will all be enabled through natural language. The application will be able to synthesize the user's preferences and plan vacations dynamically. 

Based on our doomscrolling behavior, preferences can be extracted and compiled into a convenient products list that the user sets aside a budget for. Why go shopping for stuff if the products bought are a perfect fit for your needs?

Time and task management will be automated, with just the right amount of leisure to keep you on the grind. 

The chatbots today are the excel sheets of the pre-SaaS computing days. Workflows will be written by users, to be streamlined by developers for publishing to the protocol.

### MCP Limitations as of current month

- Auth
- Payments
- Preference knowledge graph
- Security
- Packaging & Deployment
- Analytics (What's the context in which my server is used?)
- Bidirectional concurrent connections
- Tool routing scheme
- Generative UI to interact with tools

MCP will certainly not the only protocol to conform to in the future. There will be other protocols that facilitate realtime data, with some of the limitations addressed. Conformance and publishing will still be a job for nerds who don't mind being the last humans to be left in the loop.