--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: cargo_types; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE cargo_types (
    id integer NOT NULL,
    remote_id integer,
    maintype character varying(255),
    subtype character varying(255),
    subsubtype character varying(255),
    subsubsubtype character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: cargo_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cargo_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cargo_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cargo_types_id_seq OWNED BY cargo_types.id;


--
-- Name: companies; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE companies (
    id integer NOT NULL,
    name character varying(255),
    email character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: companies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE companies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: companies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE companies_id_seq OWNED BY companies.id;


--
-- Name: configurations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE configurations (
    id integer NOT NULL,
    company_name character varying(255),
    company_address1 character varying(255),
    company_address2 character varying(255),
    bank_name character varying(255),
    bank_address1 character varying(255),
    bank_address2 character varying(255),
    swift_code character varying(255),
    bsb_number character varying(255),
    ac_number character varying(255),
    ac_name character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: configurations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE configurations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: configurations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE configurations_id_seq OWNED BY configurations.id;


--
-- Name: currencies; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE currencies (
    id integer NOT NULL,
    name character varying(255),
    code character varying(255),
    symbol character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: currencies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE currencies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: currencies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE currencies_id_seq OWNED BY currencies.id;


--
-- Name: disbursment_revisions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE disbursment_revisions (
    id integer NOT NULL,
    disbursment_id integer,
    data hstore,
    fields hstore,
    descriptions hstore,
    "values" hstore,
    values_with_tax hstore,
    codes hstore,
    tax_exempt boolean DEFAULT false,
    number integer,
    cargo_qty integer DEFAULT 0,
    days_alongside integer DEFAULT 0,
    loadtime integer DEFAULT 0,
    tugs_in integer DEFAULT 0,
    tugs_out integer DEFAULT 0,
    reference character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    cargo_type_id integer,
    comments hstore,
    eta date,
    compulsory hstore,
    overriden hstore,
    disabled hstore,
    user_id integer,
    anonymous_views integer DEFAULT 0,
    pdf_views integer DEFAULT 0
);


--
-- Name: disbursment_revisions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE disbursment_revisions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: disbursment_revisions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE disbursment_revisions_id_seq OWNED BY disbursment_revisions.id;


--
-- Name: disbursments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE disbursments (
    id integer NOT NULL,
    port_id integer,
    vessel_id integer,
    company_id integer,
    status_cd integer DEFAULT 0,
    publication_id character varying(255),
    tbn boolean DEFAULT false,
    grt numeric,
    nrt numeric,
    dwt numeric,
    loa numeric,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    terminal_id integer,
    user_id integer
);


--
-- Name: disbursments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE disbursments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: disbursments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE disbursments_id_seq OWNED BY disbursments.id;


--
-- Name: estimate_revisions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE estimate_revisions (
    id integer NOT NULL,
    estimate_id integer,
    data hstore,
    fields hstore,
    descriptions hstore,
    "values" hstore,
    values_with_tax hstore,
    codes hstore,
    number integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    cargo_qty integer DEFAULT 0,
    days_alongside integer DEFAULT 0,
    loadtime integer DEFAULT 0,
    tugs_in integer DEFAULT 0,
    tugs_out integer DEFAULT 0
);


--
-- Name: estimate_revisions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE estimate_revisions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: estimate_revisions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE estimate_revisions_id_seq OWNED BY estimate_revisions.id;


--
-- Name: estimates; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE estimates (
    id integer NOT NULL,
    port_id integer,
    vessel_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    status_cd integer DEFAULT 0,
    publication_id character varying(255)
);


--
-- Name: estimates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE estimates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: estimates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE estimates_id_seq OWNED BY estimates.id;


--
-- Name: ports; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ports (
    id integer NOT NULL,
    name character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    currency_id integer,
    tax_id integer
);


--
-- Name: ports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ports_id_seq OWNED BY ports.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: service_updates; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE service_updates (
    id integer NOT NULL,
    service_id integer,
    user_id integer,
    old_code text,
    new_code text,
    changelog text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    document character varying(255)
);


--
-- Name: service_updates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE service_updates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: service_updates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE service_updates_id_seq OWNED BY service_updates.id;


--
-- Name: services; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE services (
    id integer NOT NULL,
    port_id integer,
    terminal_id integer,
    code text,
    item character varying(255),
    key character varying(255),
    row_order integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id integer,
    document character varying(255),
    compulsory boolean DEFAULT true
);


--
-- Name: services_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE services_id_seq OWNED BY services.id;


--
-- Name: tariffs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tariffs (
    id integer NOT NULL,
    name character varying(255),
    document character varying(255),
    user_id integer,
    port_id integer,
    terminal_id integer,
    validity_start date,
    validity_end date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: tariffs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tariffs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tariffs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tariffs_id_seq OWNED BY tariffs.id;


--
-- Name: taxes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE taxes (
    id integer NOT NULL,
    name character varying(255),
    rate numeric,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    code character varying(255)
);


--
-- Name: taxes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE taxes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: taxes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE taxes_id_seq OWNED BY taxes.id;


--
-- Name: terminals; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE terminals (
    id integer NOT NULL,
    port_id integer,
    name character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: terminals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE terminals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: terminals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE terminals_id_seq OWNED BY terminals.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    email character varying(255) DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying(255) DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying(255),
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying(255),
    last_sign_in_ip character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    uid character varying(255),
    provider character varying(255),
    first_name character varying(255),
    last_name character varying(255),
    admin boolean DEFAULT false
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: vessels; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE vessels (
    id integer NOT NULL,
    name character varying(255),
    loa numeric,
    grt numeric,
    nrt numeric,
    dwt numeric,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: vessels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE vessels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vessels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE vessels_id_seq OWNED BY vessels.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cargo_types ALTER COLUMN id SET DEFAULT nextval('cargo_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY companies ALTER COLUMN id SET DEFAULT nextval('companies_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY configurations ALTER COLUMN id SET DEFAULT nextval('configurations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY currencies ALTER COLUMN id SET DEFAULT nextval('currencies_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY disbursment_revisions ALTER COLUMN id SET DEFAULT nextval('disbursment_revisions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY disbursments ALTER COLUMN id SET DEFAULT nextval('disbursments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY estimate_revisions ALTER COLUMN id SET DEFAULT nextval('estimate_revisions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY estimates ALTER COLUMN id SET DEFAULT nextval('estimates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY ports ALTER COLUMN id SET DEFAULT nextval('ports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY service_updates ALTER COLUMN id SET DEFAULT nextval('service_updates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY services ALTER COLUMN id SET DEFAULT nextval('services_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tariffs ALTER COLUMN id SET DEFAULT nextval('tariffs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY taxes ALTER COLUMN id SET DEFAULT nextval('taxes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY terminals ALTER COLUMN id SET DEFAULT nextval('terminals_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY vessels ALTER COLUMN id SET DEFAULT nextval('vessels_id_seq'::regclass);


--
-- Name: cargo_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cargo_types
    ADD CONSTRAINT cargo_types_pkey PRIMARY KEY (id);


--
-- Name: companies_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY companies
    ADD CONSTRAINT companies_pkey PRIMARY KEY (id);


--
-- Name: configurations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY configurations
    ADD CONSTRAINT configurations_pkey PRIMARY KEY (id);


--
-- Name: currencies_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY currencies
    ADD CONSTRAINT currencies_pkey PRIMARY KEY (id);


--
-- Name: disbursment_revisions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY disbursment_revisions
    ADD CONSTRAINT disbursment_revisions_pkey PRIMARY KEY (id);


--
-- Name: disbursments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY disbursments
    ADD CONSTRAINT disbursments_pkey PRIMARY KEY (id);


--
-- Name: estimate_revisions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY estimate_revisions
    ADD CONSTRAINT estimate_revisions_pkey PRIMARY KEY (id);


--
-- Name: estimates_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY estimates
    ADD CONSTRAINT estimates_pkey PRIMARY KEY (id);


--
-- Name: ports_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ports
    ADD CONSTRAINT ports_pkey PRIMARY KEY (id);


--
-- Name: service_updates_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY service_updates
    ADD CONSTRAINT service_updates_pkey PRIMARY KEY (id);


--
-- Name: services_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY services
    ADD CONSTRAINT services_pkey PRIMARY KEY (id);


--
-- Name: tariffs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tariffs
    ADD CONSTRAINT tariffs_pkey PRIMARY KEY (id);


--
-- Name: taxes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY taxes
    ADD CONSTRAINT taxes_pkey PRIMARY KEY (id);


--
-- Name: terminals_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY terminals
    ADD CONSTRAINT terminals_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: vessels_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY vessels
    ADD CONSTRAINT vessels_pkey PRIMARY KEY (id);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- PostgreSQL database dump complete
--

INSERT INTO schema_migrations (version) VALUES ('20130116125348');

INSERT INTO schema_migrations (version) VALUES ('20130123211947');

INSERT INTO schema_migrations (version) VALUES ('20130123212055');

INSERT INTO schema_migrations (version) VALUES ('20130123212244');

INSERT INTO schema_migrations (version) VALUES ('20130123235549');

INSERT INTO schema_migrations (version) VALUES ('20130124000855');

INSERT INTO schema_migrations (version) VALUES ('20130124005800');

INSERT INTO schema_migrations (version) VALUES ('20130124204511');

INSERT INTO schema_migrations (version) VALUES ('20130125010942');

INSERT INTO schema_migrations (version) VALUES ('20130125011024');

INSERT INTO schema_migrations (version) VALUES ('20130125011126');

INSERT INTO schema_migrations (version) VALUES ('20130125013410');

INSERT INTO schema_migrations (version) VALUES ('20130125123702');

INSERT INTO schema_migrations (version) VALUES ('20130220165332');

INSERT INTO schema_migrations (version) VALUES ('20130221153937');

INSERT INTO schema_migrations (version) VALUES ('20130222091947');

INSERT INTO schema_migrations (version) VALUES ('20130222093256');

INSERT INTO schema_migrations (version) VALUES ('20130222093818');

INSERT INTO schema_migrations (version) VALUES ('20130222094008');

INSERT INTO schema_migrations (version) VALUES ('20130222121420');

INSERT INTO schema_migrations (version) VALUES ('20130301153738');

INSERT INTO schema_migrations (version) VALUES ('20130301153900');

INSERT INTO schema_migrations (version) VALUES ('20130301171034');

INSERT INTO schema_migrations (version) VALUES ('20130312150618');

INSERT INTO schema_migrations (version) VALUES ('20130312151332');

INSERT INTO schema_migrations (version) VALUES ('20130313091336');

INSERT INTO schema_migrations (version) VALUES ('20130313140148');

INSERT INTO schema_migrations (version) VALUES ('20130313140611');

INSERT INTO schema_migrations (version) VALUES ('20130313193707');

INSERT INTO schema_migrations (version) VALUES ('20130405175007');

INSERT INTO schema_migrations (version) VALUES ('20130405175028');

INSERT INTO schema_migrations (version) VALUES ('20130412184133');

INSERT INTO schema_migrations (version) VALUES ('20130416154537');

INSERT INTO schema_migrations (version) VALUES ('20130416161933');

INSERT INTO schema_migrations (version) VALUES ('20130426053551');

INSERT INTO schema_migrations (version) VALUES ('20130503055555');

INSERT INTO schema_migrations (version) VALUES ('20130503060013');

INSERT INTO schema_migrations (version) VALUES ('20130503060144');

INSERT INTO schema_migrations (version) VALUES ('20130503080135');

INSERT INTO schema_migrations (version) VALUES ('20130503080157');

INSERT INTO schema_migrations (version) VALUES ('20130515132211');

INSERT INTO schema_migrations (version) VALUES ('20130515155708');

INSERT INTO schema_migrations (version) VALUES ('20130515160944');

INSERT INTO schema_migrations (version) VALUES ('20130517090244');

INSERT INTO schema_migrations (version) VALUES ('20130531145814');

INSERT INTO schema_migrations (version) VALUES ('20130531151258');

INSERT INTO schema_migrations (version) VALUES ('20130531151903');