# Aspen

Aspen is a simple markup language that transforms simple narrative information into rich graph data for use in Neo4j.

To put it another way, Aspen transforms narrative text to Cypher, specifically for use in creating graph data.

In short, Aspen transforms this:

```cypher
(Matt) [knows] (Brianna)
```

into this:

```cypher
MERGE (Person {name: "Matt"})-[:KNOWS]->(Person {name: "Brianna"})
```

(It's only slightly more complicated than that.)


## Installation

Right now, installation is a little rough. We plan to resolve this soon.

Make sure you have Ruby 2.6+. Clone this repository, `cd` into it, and run `bundle install`.

## Usage

Before reading this, make sure you know basic Cypher, to the point that you're comfortable writing statements that create and/or query multiple nodes and edges.

### Command-Line Interface

#### Compilation

Once you write an Aspen file, compile it to Cypher (`.cql`) by running:

```sh
$ bundle exec aspen compile /path/to/an-aspen-file.aspen
```

This will generate a file Cypher file in the same folder, at `path/to/file.cql`.

#### (On the roadmap) Aspen Notebook

Aspen will eventually ship with a "notebook", a simple web application so you can write Aspen narratives and discourses on the left and see the Cypher or graph visualization on the right. This can help with iteratively building data in Aspen.

### Aspen Tutorial

#### Terminology

There are two important concepts in Aspen: __narratives__ and __discourses__.

A __narrative__ is a description of data that records facts, observations, and perceptions about relationships. For example, in an Aspen file, we'll write `(Matt) [knows] (Brianna)` to describe the relationship between these two people.

A __discourse__ is a way of speaking or writing about a subject. Because Aspen doesn't automatically know what `(Matt) [knows] (Brianna)` means, we have to tell it. It knows that Matt and Brianna will be nodes, but doesn't know what their labels or attributes will be.

In an Aspen file, the discourse is written at the top, and the narrative is written at the bottom. If you're coming from a software development background, you can think of the discourse as a sort of configuration that will be used to build the Cypher file that results from the Aspen narrative.

Here's an example of an Aspen file, with discourse and narrative sections marked:

```aspen
# Discourse
default Person, name

# Narrative
(Matt) [knows] (Brianna).
(Eliza) [knows] (Brianna).
(Matt) [knows] (Eliza).
```

If the concepts of discourse and narrative aren't fully clear right now, that's okay—keep going. The rest of the tutorial should shed light on them. Also, this README was written pretty quickly, and if you have suggestions, please get in touch—your feedback will be well-received and appreciated!

#### Syntax

The simplest case for using Aspen is a simple relationship between two people.

> Matt knows Brianna.

Aspen doesn't know which of these are nodes and which are edges, so we have to tell it by adding parentheses `()` to indicate nodes and square brackets `[]` to indicate edges. This should look familiar if you've ever written Cypher—these conventions are the same intentionally.

```aspen
(Matt) [knows] (Brianna).
```

Now that that's out of the way, let's think about what we can conclude from this statement:

- The strings of text `"Matt"` and `"Brianna"` are names
- Matt and Brianna are people, so they would have a Person label
- If Matt knows Brianna, Brianna knows Matt as well, so the relationship "knows" is reciprocal

However, Aspen doesn't know any of this automatically!

So, we need to tell Aspen:

- What attribute to assign the text `"Matt"` and `"Brianna"`
- What kind of labels to apply to the nodes
- That the relationship "knows" is implicitly reciprocal

##### Default label and attribute name

First, need to tell Aspen that, when it encounters an unlabeled node, that it should assume it's a person, and that the text is the name of the person.

So, let's add a `default` line to the discourse section of the file, up at the top. This directs Aspen to assign unlabeled nodes a `:Person` label, and to use the an attribute called `name` when assigning the text inside the parentheses.

```
 # Discourse
default Person, name

# Narrative
(Matt) [knows] (Brianna).
```

When we run this, we get this Cypher:

```cypher
MERGE (person_matt:Person { name: "Matt" })
MERGE (person_brianna:Person { name: "Brianna" })

MERGE (person_matt)-[:KNOWS]->(person_brianna)
```

##### Reciprocal relationships

However, we want the relationship "knows" to be reciprocal.

> Note on reciprocal relationships:
>
> In Neo4j, the convention is for reciprocal (also known as bidirectional or undirected) relationships to be represented by a directional relationship. [Read more at GraphAware](https://graphaware.com/neo4j/2013/10/11/neo4j-bidirectional-relationships.html).
>
> However, we want our resulting Cypher to show a reciprocal relationship so we can read the Cypher and understand the intent of the code.

In Cypher, if we wanted to show we intend to create a reciprocal relationship, we'd write "Matt knows Brianna" as follows. Notice there's no arrowhead.

```cypher
...

MERGE (person_matt)-[:KNOWS]-(person_brianna)
```

To get this reciprocality, we list all the reciprocal relationships after the keyword   `reciprocal`:

```aspen
# Discourse
default Person, name
reciprocal knows

# Narrative
(Matt) [knows] (Brianna).
```

This gives us the undirected relationship in Cypher that we want!


##### Multiple node types

First off, we want to clarify that while you can't write nodes in Cypher-like syntax in Aspen right now like the below node, that's one of the next parts of the language we're planning to build.

```cypher
(Person { name: 'Matt', state: 'MA' })
```

So to be super clear, there isn't a way to assign multiple attributes to a node at the moment.

But, let's review how to handle when you have another node type (aka label) in your data.

Let's say we want to represent an Employer, and the employer's name is UMass Boston.

```aspen
default Person, name

...
(Matt) [works at] (Employer, UMass Boston)
```

Note how this node starts with a label, followed by a comma, followed by the attribute we want to include.

In order to tell Aspen to assign the text "UMass Boston" to an attribute called `company_name`, we add a `default_attribute` statement to the discourse section.

```
# Discourse
default Person, name
default_attribute Employer, name

# Narrative
(Matt) [works at] (Employer, UMass Boston)
```

Let's go over the differences between `default` and `default_attribute`.

The `default` directive will catch any unlabeled nodes, like `(Matt)`, and label them. It will then assign the text inside the parentheses, `"Matt"`, to the attribute given as the default. If the default is `Person, name`, it will create a Person node with name "Matt".

The `default_attribute` directive will assign any nodes with the given label to the given attribute. So Aspen like `(Employer, ACME Corp.)` will create a node like

```cypher
(:Employer, name: { "ACME Corp." })
```


The whole code all together is:

```
# Discourse
default Person, name
default_attribute Employer, company_name
reciprocal knows

# Narrative
(Matt) [knows] (Brianna).
(Matt) [works at] (Employer, UMass Boston).
```

The Cypher produced generates the reciprocal "knows" relationship, and the one-way employment relationship.

```cypher
MERGE (person_matt:Person { name: "Matt" })
MERGE (person_brianna:Person { name: "Brianna" })
MERGE (employer_umass_boston:Employer { company_name: "UMass Boston" })

MERGE (person_matt)-[:KNOWS]-(person_brianna)
MERGE (person_matt)-[:WORKS_AT]->(employer_umass_boston)
;
```

## Background

### Problem Statement

@beechnut, the lead developer of Aspen, attempted to model a simple conflict scenario in Neo4j's language Cypher, but found it took significantly longer than expected. He ran into numerous errors because it wasn't obvious how to construct nodes and edges through simple statements.

It is a given that writing Cypher directly is time-consuming and error-prone, especially for beginners. This is not a criticism of Cypher—we love Cypher and think it's extremely-well designed. Aspen is just attempting to make it easier to generate data by hand.

### Hypotheses

We assume that most graph data is constructed through a myriad of ways besides free-form text. We *also* assume that if the tools existed to support converting semi-structured text to graph data, these tools would find wide use in a variety of fields.

We believe that graph databases and graph algorithms can provide deep insights into complex systems, and that people would find value in converting simple narrative descriptions into graph data.

## Roadmap

- Custom grammars - matching sentences to Cypher statements
- Schema and attribute protections - so a typo doesn't mess up your data model)
- Short nicknames & attribute uniqueness - so you can avoid accidental data duplication when "Matt" and "Matt Cloyd" are the same person
- Custom attribute handling functions - if your default nodes could either be a first name or a full name, switch between attributes
- Aspen Notebook - live connection between Aspen and a playground Neo4j instance
- Aspen Notebook publishing - publish data to a development/test/production Neo4j instance (and perhaps view diffs)
- Two-way conversion between Neo4j data and Aspen

Are you interested in seeing any of these features come to life? If so, [get in touch](mailto:cloyd.matt@gmail.com) so we can talk about feature sponsorship!


## Code of Conduct

We expect that anyone working on this project will be good and kind to each other. We're developing software about relationships, and anyone who works on this project is expected to have healthy relating skills.

Everyone interacting in the Aspen project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/beechnut/aspen/blob/master/CODE_OF_CONDUCT.md).

The full Code of Conduct is available at CODE_OF_CONDUCT.md.


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/beechnut/aspen. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/beechnut/aspen/blob/master/CODE_OF_CONDUCT.md).

If you'd like to see Aspen grow, please [get in touch](mailto:cloyd.matt@gmail.com), whether you're a developer, user, or potential sponsor. We have ideas on ways to grow Aspen, and we need your help to do so, whatever form that help takes. We'd love to invite a corporate sponsor to help inform and sustain Aspen's growth and development.



## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

